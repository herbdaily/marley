RESTRICT_HIDE=1;
RESTRICT_RO=2;
RESTRICT_REQ=4;
NAME_INDEX=1;
TYPE_INDEX=PROPS_INDEX=2;
RESTRICTIONS_INDEX=2;
VALUE_INDEX=3;
String.prototype.humanize=function(){return pl.map(this.split('_'),function(w){return w[0].toUpperCase()+w.slice(1)}).join(' ');}
pl(function(){
  pl('body').html(j.toDom(_jamaica_json));
  pl.win_bind('form','submit',j.formSubmit);
  pl.win_bind('ul.menu li a','click',j.menuClick);
});

j={
  ajax_defaults:{
    load:function(){pl('body').css('cursor','wait')},
    always:function(){pl('body').css('cursor','default');},
    success:function(json){pl('#'+this.id).html(j.toDom(json)); },
    error:function(stat,json){
      var err=JSON.parse(json);
      var attrs=err[1];
      var frm_id=this.id;
      if (attrs.error_type=='validation') {
        for (col in attrs.error_details) {
          pl('#'+frm_id+' [id$=__'+col+']').addClass('errorCol').after(j.toDom(["p",{"class":"errorMsg"},attrs.error_details[col]]));
        }
      }
    },
  },
  make_ajax_params:function(params){
    return pl.extend(params,
        pl.extend(pl.get_callbacks.call(this,j.ajax_defaults),{
          dataType:'json',
          url:this.href || this.action,
          type: this.method ? this.method.toUpperCase() : 'GET'
        })
    );
  },
  menuClick:function(e){
    e.preventDefault();
    var target='#'+pl(this).parent().attr('class').replace(/__nav$/,'__content')
    pl.ajax(j.make_ajax_params.call(this,{success:function(json){pl(target).html(j.toDom(json))}}))
  },
  formSubmit:function(e){
    e.preventDefault();
    pl.ajax(j.make_ajax_params.call(this,{data:pl.serialize(this.id)}))
  },
  toggleColStat:function(e){
  },
  colEditKeypress:function(e){
  },
  instanceActionClick:function(e){
  },
  deleteResource:function(e){
  },
  toDom:function(json){
    return j.domFunc[pl.type(json)].call(json);
  },
  domFunc:{
    'str' : function(){ return document.createTextNode(this);},
    'int' : function(){ return document.createTextNode(this);},
    'arr' : function(){
      this.isNodeSpec=function(){return pl.type(this[0],'str') && pl.type(this[1],'obj')}
      this.nodeType=this[0];
      this.attrs=this[1];
      this.content=this[2];
      if(this.isNodeSpec()) {
        if (node_type=j.nodeTypes[this.nodeType]) {
          return j.toDom(node_type(this));
        } else {
          var foo=this
          var dom=pl('<'+ this.nodeType+'>',this.attrs);
          if(this.content){
            var content=j.toDom(this.content);
            if (pl.type(content,'arr')) {
              pl.each(content, function() {dom.append(this)})
            } else {
              dom.append(content)
            }
          }
          return dom.get();
        }
      } else {
        return pl.map(this, function(e){return j.toDom(e)})
      }
    }
  },
  nodeTypes:{
    "link":function(l){
      return ["a",{"href":l.attrs.url},l.attrs.title];
    },
    "msg":function(m){
      return ["p",{"class":"message"},m.content];
    },
    "section":function(m){
      var attrs=m.attrs;
      var nav=pl.map(attrs.navigation,function(i){return ["li",{"class":attrs.name+'__nav'},[i]]});
      return ["div",{"class":"section","id":attrs.name+"__section"},
        [ ["h1",{},attrs.title],
        ["div",{"class":"menuDescription"},attrs.description],
        ["ul",{"id":attrs.name+"__menu","class":"menu"},nav],
        ["div",{"id":attrs.name+"__content"}," "] ]
      ];
    },
    "instance":function(i) {
      var ctl;
      var attrs=i.attrs;
      var instance_id=attrs.new_rec ? 'new' : attrs.schema[0][VALUE_INDEX]
      if (attrs.search){
        attrs.new_rec=true;
        var frm=["form",{"action":attrs.url,"method":"get","class":"search","id":attrs.name+'__search__form'}];
      } else {
        var frm=["form",{"action":attrs.url,"method":"post","class":attrs.name+"Instance instance","id":attrs.name+'__'+instance_id+'__form'}];
      }
      var contents=attrs.description ? [["div",{"class":"form_description"}, attrs.description]] : [];
      if(! attrs.new_rec){
        frm[1].action+="/"+attrs.schema[0][VALUE_INDEX]
        contents.push(["input",{"type":"hidden","name":"_method","value":"put"}])
      }
      pl.each(attrs.schema, function(i,col){
        var props={"id":attrs.name+"__"+col[1]};
        props.name=j.id2name(props.id);
        props.value=col[VALUE_INDEX] || "";
        if(col[RESTRICTIONS_INDEX] & RESTRICT_HIDE) {
          if (props.value.constructor==Array) {props.value=props.value[0];}  //many_to_one 
          props.type="hidden";
          contents.push(["input",props]);
        } else{
          if (! attrs.new_rec) {props["class"]="hidden "} //hide the actual controls in existing records
          if (col[RESTRICTIONS_INDEX] & RESTRICT_RO) {
            if (props.value.constructor==Array) {props.value=props.value[1];}  //many_to_one 
            delete props.name;
            var v=props.value;
            delete props.value;
            //ugly as all fucking shit.  Will suffice for now.
            //if(col[0]=="clob"){  v=$.map(v.split("\n"),function(p){return [["p",{},p]]}) }
            if(col[0]=="clob"){  v=pl('<div>') }
            ctl=["div",props,v];
          } else {
            if (c=j.colTypes[col[0]]) {
              ctl=c(props);
            } else {
              props["type"]='text';
              props["class"] || (props["class"]="")
              props["class"]+=col[0];
              ctl=["input",props];
            }
            if (! attrs.new_rec) {
              var show_val;
              if (ctl[1].constructor==Array){ //many to one
                show_val=ctl[1][1].value
              } else if (col[0]=="image") {
                show_val=["img",{"src":ctl[1].value}]
              } else if(col[0]=="clob"){  //ugly as all fucking shit.  Will suffice for now.
                //show_val=$.map(col[VALUE_INDEX].split("\n"),function(p){return [["p",{},p]]})
                show_val=pl('<div>').html(col[VALUE_INDEX]);
              } else {
                show_val=ctl[1].value || ctl[2] //textarea value
              }
              ctl=["div",{"class":"editable col"},[ctl,["span",{},show_val]]] 
            }
          }
          contents.push(["div",{"class":props.id+"ColContainer colContainer"},[["label",{"for":props.id},col[1].humanize()+":"],ctl]]);
        }
      });
      if (attrs.search){
        contents.push(["input",{"type":"submit","value":"Search"}]);
      } else {
        contents.push(["input",{"type":"submit","value":"Save","class":"submit " + (attrs.new_rec ? "" : "hidden")}]);
      }
      if ((! attrs.new_rec) && (iga=attrs.instance_get_actions)){
        contents.push(["div",{"class":"instanceActions"},pl.map(iga,function(action){return [["a",{"class":"instanceAction "+action},action.humanize()]]})]);
      }
      frm.push(contents);
      var content=i.content || [];
      content.unshift(frm);
      return ["div",{"class":"instanceContainer"},content];
    }
  },
  colTypes:{
    "password":function(props) {
      props.type="password";
      return ["input",props];
    },
    "clob":function(props) {
      var v=props.value;
      delete props.value;
      return ["textarea",props,v];
    },
    "image":function(props){
      props.type="file";
      return["input",props]
    },
    "many_to_one":function(props) {
      var hprops=JSON.parse(JSON.stringify(props));
      hprops.type="hidden";
      hprops.name=j.id2name(hprops.id);
      hprops.value=props.value[0];
      props.type="text";
      props.value=props.value[1];
      props.id=props.id.replace(/_id$/,"");
      props.name=j.id2name(props.id);
      return [["input",hprops],["input",props]]
    }
  },
  "id2name":function (s) {
    parts=s.split('__');
    name=parts.shift();
    pl.each(parts,function(i,part){name+='['+part+']'});
    return name;
  }
}
