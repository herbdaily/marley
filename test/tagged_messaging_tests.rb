
class MessageTests < Test::Unit::TestCase
  def initialize(*args)
    super
    MR::User.delete
    @client=Marley::TestClient.new(:resource_name => 'user')
    ['user1','user2','user3'].each do |un|
      MR::User.new(:name => un,:password => 'asdfasdf', :confirm_password => 'asdfasdf').save
    end
    @user1_auth=['user1','asdfasdf']
    @user2_auth=['user2','asdfasdf']
    @user3_auth=['user3','asdfasdf']
  end
  def setup
    MR::Message.delete
    MR::Tag.delete
    DB[:messages_tags].delete
  end
  context "Private Messages" do
    setup do
      @client.resource_name='private_message'
      @pm=MR::PrivateMessage.new.to_a
    end
    context "regular user (user1) logged in" do
      setup do
        @client.auth=@user1_auth
      end
      should "show PM list and new PM form" do
        assert @client.read({})
        assert @client.read({}, :method => 'new')
      end
      should "validate new user generated PMs properly" do
        #reject a PM with only recipients
        @pm.col_value(:recipients, 'user2')
        resp=@client.create(@pm,{:code => 400})
        assert_equal :error, resp.resource_type
        assert_equal "validation", resp.error_type
        assert_equal ["is required"], resp.error_details[:title]
        assert_equal ["is required"], resp.error_details[:message]
        #reject a PM to a non-existent user
        @pm.col_value(:recipients, 'asdfasdfasdf')
        resp=@client.create(@pm,{:code => 400})
        assert_equal :error, resp.resource_type
        assert_equal "validation", resp.error_type
        assert resp.error_details[:recipients][0]
        #accept a PM to user3
        @pm.col_value(:recipients, 'user3')
        assert @client.create({:'private_message[recipients]' => 'user3',:'private_message[title]' => 'asdf',:'private_message[message]' => 'asdf'})
      end
    end
    context "user3 logged in" do
      setup do
        @client.auth=@user3_auth
      end
      should "validate new user3 generated PMs properly" do
        resp=@client.create(@pm.set_values(:recipients => 'user2'),{:code => 400})
        assert_equal :error, resp.resource_type
        assert_equal "validation", resp.error_type
        assert_equal ["is required"], resp.error_details[:title]
        assert_equal ["is required"], resp.error_details[:message]
      end
      should "accept a PM to user1" do
         assert @client.create(@pm.set_values(:'recipients' => 'user1',:'title' => 'asdf',:'message' => 'asdf'))
      end
    end
    context "message with no tags" do
      setup do
        @client.auth=@user3_auth
        @client.create(@pm.set_values({:'recipients' => 'user1',:'title' => 'asdf',:'message' => 'asdf'}))
      end
      should "show up in PM list of sender and receiver" do
        resp=@client.read({})
        assert_equal 1, resp.length
        resp=@client.read({},{:auth => @user1_auth})
        assert_equal 1, resp.length
      end
      should "have sent tag for sender" do
        resp=@client.read({})
        assert_equal 3, resp[0].length
        assert_equal "sent", resp.find_instances('user_tag')[0].schema[:tag].col_value
      end
      should "have inbox tag for receiver" do
        resp=@client.read({},{:auth => @user1_auth})
        assert_equal 3, resp[0].length
        assert_equal "inbox", resp.find_instances('user_tag')[0].schema[:tag].col_value
      end
      should "have reply, reply_all and new_tags instance get actions" do
        resp=@client.read({})
        assert_same_elements ['reply','reply_all','new_tags'], resp[0].actions[:get]
      end
      context "user1 instance actions" do
        setup do
          @client.auth=@user1_auth
          @msg=@client.read({})[0]
          @client.instance_id=@msg.schema[:id].col_value
          @reply=@client.read({},{:method => 'reply'})
          @new_tags=@client.read({},:method => 'new_tags')
        end
        context "reply" do
          should "have author in to field and default title beginning with 're:'" do
            assert_equal 'user3', @reply.schema[:recipients].col_value
            assert_equal 're: ', @reply.schema[:title].col_value[0 .. 3]
          end
          should "accept reply" do
            assert @client.create(@reply.set_values('message' => 'asdf'),{:method => nil,:instance_id => nil})
          end
        end
        context "new tags" do
          should "return tag instance with name tag and same url as original message" do
            assert_equal 'tags', @new_tags.name
            assert_equal "#{@msg.url}/tags", @new_tags.url
          end
          should "accept new tags, which should then show up with the original message" do
            assert @client.create({'private_message[tags]' => 'added_tag1, added_tag2'},{:method => 'tags'})
            msg=@client.read({})
            user_tags=msg.find_instances('user_tag')
            assert_same_elements ["inbox", "added_tag1", "added_tag2"], user_tags.map{|t| t.schema[:tag].col_value}
          end
        end
      end
    end
    context "message with 2 tags" do
      setup do
        @client.auth=@user3_auth
        @client.create(@pm.set_values(:recipients => 'user1', :title => 'asdf', :message => 'asdf', :tags => 'test,test2'))
      end
      context "sender (user3) logged in" do
        setup do
          @msg=@client.read[0]
          @tags=@msg.find_instances('user_tag')
        end
        should "have sent tag and both specified tags for sender" do
          assert_same_elements ["sent", "test", "test2"], @tags.map{|t| t.schema[:tag].col_value}
        end
        should "allow sender to remove his own tags'" do
          assert_equal 'remove_parent', @tags[0].actions[:delete]
          assert @client.del({},{:url => @tags[0].url+@msg.url})
          assert_equal 2, @client.read[0].find_instances('user_tag').length
        end
      end
      context "receiver (user1)" do
        setup do
          @client.auth=@user1_auth
          @msg=@client.read[0]
          @tags=@msg.find_instances('user_tag')
        end
        should "have inbox tag and both specified tags" do
          assert_same_elements ["inbox", "test", "test2"], @tags.map{|t| t.schema[:tag].col_value}
        end
        should "have specified tags in reply" do
          reply=@client.read({},{:instance_id => @msg.schema[:id].col_value,:method => 'reply'})
          assert_equal 'test,test2', reply.schema[:tags].col_value
        end
        should "allow receiver to remove his own tags'" do
          assert_equal 'remove_parent', @tags[0].actions[:delete]
          assert @client.del({},{:url => @tags[0].url+@msg.url})
          assert_equal 2, @client.read[0].find_instances('user_tag').length
        end
      end
      context 'user2' do
        should "have no messages" do
          assert resp=@client.read({},{:auth => @user2_auth})
          assert_equal 0, resp.length
        end
      end
    end
    context "message with 2 tags and 2 receivers" do
      setup do
        @client.create(@pm.set_values(:recipients => 'user1,user2',:title => 'asdf',:message => 'asdf', :tags => 'test,test2'),{:auth => @user3_auth})
      end
      should "have sent tag and both specified for sender" do
        resp=@client.read({},{:auth => @user3_auth})
        user_tags=resp[0].find_instances('user_tag')
        assert_same_elements ["sent", "test", "test2"], user_tags.map{|t| t.schema[:tag].col_value}
      end
      should "have inbox tag and both specified for 1st receiver (user1)" do
        resp=@client.read({},{:auth => @user1_auth})
        user_tags=resp[0].find_instances('user_tag')
        assert_same_elements ["inbox", "test", "test2"], user_tags.map{|t| t.schema[:tag].col_value}
      end
      should "have inbox tag and both specified for 2st receiver (user2)" do
        resp=@client.read({},{:auth => @user2_auth})
        user_tags=resp[0].find_instances('user_tag')
        assert_same_elements ["inbox", "test", "test2"], user_tags.map{|t| t.schema[:tag].col_value}
      end
    end
    context "message listing" do
      setup do
        #3 messages with tag "test" for user 1
        @client.create(@pm.set_values(:'recipients' => 'user1',:'title' => 'title1',:'message' => 'body1', :'tags' => 'test'),{:auth => @user3_auth})
        @client.create(@pm.set_values(:'recipients' => 'user1',:'title' => 'title2',:'message' => 'body2', :'tags' => 'test'),{:auth => @user3_auth})
        @client.create(@pm.set_values(:'recipients' => 'user1',:'title' => 'title3',:'message' => 'body3', :'tags' => 'test'),{:auth => @user3_auth})
        #2 messages with tag "test1" for user1 and user2
        @client.create(@pm.set_values(:'recipients' => 'user2,user1',:'title' => 'title1',:'message' => 'body1', :'tags' => 'test1'),{:auth => @user3_auth})
        @client.create(@pm.set_values(:'recipients' => 'user2,user1',:'title' => 'title2',:'message' => 'body2', :'tags' => 'test1'),{:auth => @user3_auth})
      end
      should "for sender (user3) show 3 messages with 'test' tag,2 messages with 'test1' tag, and 5 messages with 'sent' tag" do
        @client.auth=@user3_auth
        assert_equal 3, @client.read({:'private_message[tags]' => 'test'}).length
        assert_equal 2, @client.read({:'private_message[tags]' => 'test1'}).length
        assert_equal 5, @client.read({:'private_message[tags]' => 'sent'}).length
      end
      should "for user1 show 3 messages with 'test' tag, 2 messages with 'test1' tag, 5 messages with 'inbox' tag, and 5 messages with 'test' or 'test1' tags" do
        @client.auth=@user1_auth
        assert_equal 3, @client.read({:'private_message[tags]' => 'test'}).length
        assert_equal 2, @client.read({:'private_message[tags]' => 'test1'}).length
        assert_equal 5, @client.read({:'private_message[tags]' => 'inbox'}).length
        assert_equal 5, @client.read({:'private_message[tags]' => 'test,test1'}).length
      end
      should "for user2 show 0 messages with 'test' tag, 2 messages with 'test1' tag, 2 messages with 'inbox' tag and 2 messages with 'test' or 'test1' tags" do
        @client.auth=@user2_auth
        assert_equal 0, @client.read({:'private_message[tags]' => 'test'}).length
        assert_equal 2, @client.read({:'private_message[tags]' => 'test1'}).length
        assert_equal 2, @client.read({:'private_message[tags]' => 'inbox'}).length
        assert_equal 2, @client.read({:'private_message[tags]' => 'test,test1'}).length
      end
    end
  end
  context "Public Messages" do
    setup do
      @client.resource_name='public_message'
      @post=MR::PublicMessage.new.to_a
    end
    context 'validation' do
      should "get a validation error trying to post without a title or message as user3, user1, or user2" do
        resp=@client.create({},{:code => 400,:auth => @user3_auth})
        assert_equal :error, resp.resource_type
        assert_equal "validation", resp.error_type
        assert_equal ["is required"], resp.error_details[:title]
        assert_equal ["is required"], resp.error_details[:message]
        user1_resp=@client.create({},{:code => 400,:auth => @user1_auth})
        assert_equal user1_resp, resp
        user2_resp=@client.create({},{:code => 400,:auth => @user2_auth})
        assert_equal user2_resp, resp
      end
      should "be able to post with title and message as user3, user1, or user2" do
        assert @client.create(@post.set_values('title' => 'test', 'message' => 'asdf'),{:auth => @user3_auth})
        assert_equal 1, @client.read({},{:auth => @user1_auth}).length
        assert @client.create(@post.set_values('title' => 'test', 'message' => 'asdf'),{:auth => @user1_auth})
        assert_equal 2, @client.read({},{:auth => @user2_auth}).length
        assert @client.create(@post.set_values('title' => 'test', 'message' => 'asdf'),{:auth => @user2_auth})
        assert_equal 3, @client.read({},{:auth => @user3_auth}).length
      end
    end
    should 'list posts by public tags' do
      @client.create(@post.set_values('title' => 'test', 'message' => 'asdf','tags' => 'user3tag1,user3tag2'),{:auth => @user3_auth})
      @client.create(@post.set_values('title' => 'test', 'message' => 'asdf','tags' => 'user3tag1,user3tag2,user3tag3'),{:auth => @user3_auth})
      @client.create(@post.set_values('title' => 'test', 'message' => 'asdf','tags' => 'user1tag1'),{:auth => @user1_auth})
      @client.create(@post.set_values('title' => 'test', 'message' => 'asdf','tags' => 'user1tag1,user1tag2'),{:auth => @user1_auth})
      @client.create(@post.set_values('title' => 'test', 'message' => 'asdf','tags' => 'user1tag1,user1tag2,user1tag3'),{:auth => @user1_auth})
      @client.create(@post.set_values('title' => 'test', 'message' => 'asdf','tags' => 'user2tag1,user2tag2,user2tag3'),{:auth => @user2_auth})
      @client.create(@post.set_values('title' => 'test', 'message' => 'asdf','tags' => 'user2tag1,user2tag2,user2tag3,user2tag4'),{:auth => @user2_auth})
      assert_equal 7, @client.read({},{:auth => @user3_auth}).length
      assert_equal 7, @client.read({'public_message[title]' => 'test'},{:auth => @user3_auth}).length
      assert_equal 7, @client.read({'public_message[title]' => 'test'},{:auth => @user1_auth}).length
      assert_equal 7, @client.read({'public_message[title]' => 'test'},{:auth => @user2_auth}).length
      assert_equal 2, @client.read({'public_message[tags]' => 'user3tag1'},{:auth => @user3_auth}).length
      assert_equal 2, @client.read({'public_message[tags]' => 'user3tag1'},{:auth => @user1_auth}).length
      assert_equal 1, @client.read({'public_message[tags]' => 'user3tag3'},{:auth => @user2_auth}).length
      assert_equal 1, @client.read({'public_message[tags]' => 'user3tag3'},{:auth => @user3_auth}).length
      assert_equal 2, @client.read({'public_message[tags]' => 'user1tag2'},{:auth => @user3_auth}).length
      assert_equal 3, @client.read({'public_message[tags]' => 'user1tag1'},{:auth => @user3_auth}).length
      assert_equal 3, @client.read({'public_message[tags]' => 'user1tag1'},{:auth => @user2_auth}).length
    end
    should 'have usable reply, new_tags, and new_user_tags instance actions' do
      @client.create(@post.set_values('title' => 'test', 'message' => 'asdf','tags' => 'user3tag1,user3tag2'),{:auth => @user3_auth})
      @client.auth=@user2_auth
      posts=@client.read({})
      assert_same_elements ['reply','new_tags','new_user_tags'], posts[0].actions[:get]
      reply=@client.read({},{:instance_id => posts[0].schema[:id].col_value,:method => 'reply'})
      tags=@client.read({},{:instance_id => posts[0].schema[:id].col_value,:method => 'new_tags'})
      user_tags=@client.read({},{:instance_id => posts[0].schema[:id].col_value,:method => 'new_user_tags'})
      assert_equal 're: test', reply.schema[:title].col_value
      assert @client.create(reply.set_values('message' => 'asdf'),{:method => nil,:instance_id => nil})
      assert @client.create(tags.to_params.merge('public_message[tags]' => '1,2,3'),{:url => tags.url})
      assert_same_elements ['1','2','3','user3tag1','user3tag2'], @client.read[0].find_instances('public_tag').map{|t| t.schema[:tag].col_value}
      assert @client.create(user_tags.to_params.merge('public_message[user_tags]' => '4,5,6'),{:url => user_tags.url})
      assert_same_elements ['4','5','6'], @client.read[0].find_instances('user_tag').map{|t| t.schema[:tag].col_value}
      assert_equal [], @client.read({},{:auth => @user1_auth})[0].find_instances('user_tag').map{|t| t.schema[:tag].col_value}
    end
  end
end
