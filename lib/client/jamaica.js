RESTRICT_HIDE=1;
RESTRICT_RO=2;
RESTRICT_REQ=4;
NAME_INDEX=1;
TYPE_INDEX=PROPS_INDEX=2;
RESTRICTIONS_INDEX=2;
VALUE_INDEX=3;
String.prototype.humanize=function(){return pl.map(this.replace(/^_/,'').split('_'),function(w){return w[0].toUpperCase()+w.slice(1)}).join(' ');}
pl(function(){
  pl('body').html(Reggae.call(_jamaica_json).toDom());
  pl.win_bind('a[href$=main_menu]','click',function(e){pl.get(this.href,function(json){pl('body').html(Reggae.call(json).toDom())},'json')});
  pl.win_bind('form','submit',j.formSubmit);
  pl.win_bind('ul.menu li a','click',j.menuClick);
});

j={
  ajax_defaults:{
    load:function(){pl('body').css('cursor','wait')},
    always:function(){pl('body').css('cursor','default');},
    success:function(json){pl('#'+this.id).html(Reggae.call(json).toDom()); },
    error:function(stat,json){
      var err=JSON.parse(json);
      var attrs=err[1];
      var frm_id=this.id;
      if (attrs.error_type=='validation') {
        for (col in attrs.error_details) {
          pl('#'+frm_id+' [id$=__'+col+']').addClass('errorCol').after(Reggae.call(["p",{"class":"errorMsg"},attrs.error_details[col]]).toDom());
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
    pl.ajax(j.make_ajax_params.call(this,{success:function(json){foo=json;pl(target).html(Reggae.call(json).toDom())}}))
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
}
