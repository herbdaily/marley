RESTRICT_HIDE=1;
RESTRICT_RO=2;
RESTRICT_REQ=4;
NAME_INDEX=1;
TYPE_INDEX=PROPS_INDEX=2;
RESTRICTIONS_INDEX=2;
VALUE_INDEX=3;
$(function(){

  getDisplayFunc('body')(_jamaica_json);
  $.ajaxSetup({"dataType":"json"});
  $('body').ajaxStart(function(){$('body').css('cursor','wait')});
  $('body').ajaxComplete(function(){$('body').css('cursor','default')});
  $('body').ajaxError(showError);
  $('ul.menu li a').live('click',menuClick);
  $('form.instance, form.search').live('submit',formSubmit);
  $('.editable').live('click',toggleColStat);
  $('.editing input').live('keypress',colEditKeypress);
  $('a.instanceAction').live('click',instanceActionClick);
  $('.resourceContainer .delete').live('click',deleteResource);
});

function menuClick(){
  $.get(this.href,"",getDisplayFunc($(this).closest('.section').children('.content')));
  return false;
}

function formSubmit(){
  //TEMPORARY
  if (this.action.match(/login$/)) {
    $.ajax({"url":"/menu","username":$('#login__name').val(),"password":$('#login__password').val(),"success":getDisplayFunc('body')});
  } else {
    $(this).find(".errorMsg").remove();
    $(this).find(".errorCol").removeClass("errorCol");
    $(this).ajaxSubmit({"success":getDisplayFunc($(this).closest(".instanceContainer"),"replaceWith")});
  }
  return false;
}
function toggleColStat() {
  $(this).closest('form').children(":submit").appendTo(this);
  $(this).children("input, span, textarea").toggleClass("hidden");
  $(this).toggleClass("editable editing");
  if($(this).hasClass("editing")){$(this).children("input").focus();}
}
function colEditKeypress(e){
  if (e.keyCode==27){
    toggleColStat.apply($(this).closest(".editing"));
  }
}
function instanceActionClick(){
  $.get($(this).closest(".instance").attr("action")+'/'+$(this).attr('class').replace(/.* /,""),"",getDisplayFunc($(this).closest('.instance'),"after"));
  return false;
}
function deleteResource(){
}
function getDisplayFunc(target,func){
  if (! func) {func="html"}
  return function(json) { $(target)[func](json.toDom()); }
}
function showError(e, r, s){
  $('body').css('cursor','default');
  try { 
    var [err_type,errors]=JSON.parse(r.responseText);
    var rn=s.url.replace(/^\//,'');
    if(err_type=='validation'){
      $.each (errors, function(col,msg){
        $("."+rn+"Instance #"+rn+"__"+col).addClass('errorCol');
        $("."+rn+"Instance ."+rn+"__"+col+"ColContainer").append(["p",{"class":"errorMsg"},col+" "+msg].toDom());
        $("."+rn+"Instance #"+rn+"__"+col).focus();
      });
    }
  } catch(err){ //in case it's not JSON
    alert(r.responseText);
  }

}

String.prototype.humanize=function(){return $.map(this.split('_'),function(w){return w[0].toUpperCase()+w.slice(1)}).join(' ');}
String.prototype.toDom=function(){return document.createTextNode(this);}
Number.prototype.toDom=function(){return document.createTextNode(this);}
Array.prototype.isNodeSpec=function(){return this[0] && this[0].constructor==String && this[1] && this[1].constructor==Object}
Array.prototype.toDom=function(){
  if(this.isNodeSpec()) {
    [this.nodeType, this.attrs, this.content]=this;
    if (node_type=nodeTypes[this.nodeType]) {
      return node_type(this).toDom();
    } else {
      var dom=$(document.createElement(this.nodeType)).attr(this.attrs)[0];
      if(this.content){$(dom).append(this.content.toDom ? this.content.toDom():this.content)}
      return dom;
    }
  } else {
    return $.map(this, function(e){e || (e=""); return e.toDom ? e.toDom() : e; })
  }
}
nodeTypes={
  "link":function(l){
    return ["a",{"href":l.attrs.url},l.attrs.title];
  },
  "msg":function(m){
    return ["p",{"class":"message"},m.contents];
  },
  "section":function(m){
    var attrs=m.attrs;
    var nav=$.map(attrs.navigation,function(i){return [["li",{},[i]]]});
    return ["div",{"class":"section","id":attrs.name+"__section"},
      [ ["h1",{},attrs.title],
      ["div",{"class":"menuDescription"},attrs.description],
      ["ul",{"id":attrs.name+"_menu","class":"menu"},nav],
      ["div",{"class":"content"}," "] ]
    ];
  },
  "instance":function(i) {
    var ctl;
    var attrs=i.attrs;
    if (attrs.search){
      attrs.new_rec=true;
      var frm=["form",{"action":attrs.url,"method":"get","class":"search"}];
    } else {
      var frm=["form",{"action":attrs.url,"method":"post","class":attrs.name+"Instance instance"}];
    }
    var contents=attrs.description ? [["div",{"class":"form_description"}, attrs.description]] : [];
    if(! attrs.new_rec){
      frm[1].action+="/"+attrs.schema[0][VALUE_INDEX]
      contents.push(["input",{"type":"hidden","name":"_method","value":"put"}])
    }
    contents.push($.map(attrs.schema, function(col,i){
      var props={"id":attrs.resource+"__"+col[1]};
      props.name=id2name(props.id);
      props.value=col[VALUE_INDEX] || "";
      if(col[RESTRICTIONS_INDEX] & RESTRICT_HIDE) {
        if (props.value.constructor==Array) {props.value=props.value[0];}  //many_to_one 
        props.type="hidden";
        return [["input",props]];
      } else{
        if (! attrs.new_rec) {props["class"]="hidden "} //hide the actual controls in existing records
        if (col[RESTRICTIONS_INDEX] & RESTRICT_RO) {
          if (props.value.constructor==Array) {props.value=props.value[1];}  //many_to_one 
          delete props.name;
          var v=props.value;
          delete props.value;
          //ugly as all fucking shit.  Will suffice for now.
          //if(col[0]=="clob"){  v=$.map(v.split("\n"),function(p){return [["p",{},p]]}) }
          if(col[0]=="clob"){  v=$('<div>'+v+'</div>') }
          ctl=["div",props,v];
        } else {
          if (c=colTypes[col[0]]) {
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
              show_val=$('<div>'+col[VALUE_INDEX]+'</div>');
            } else {
              show_val=ctl[1].value || ctl[2] //textarea value
            }
            ctl=["div",{"class":"editable col"},[ctl,["span",{},show_val]]] 
          }
        }
        return [["div",{"class":props.id+"ColContainer colContainer"},[["label",{"for":props.id},col[1].humanize()+":"],ctl]]];
      }
    }));
    if (attrs.search){
      contents.push(["input",{"type":"submit","value":"Search"}]);
    } else {
      contents.push(["input",{"type":"submit","value":(attrs.url=="login" ? "login" : "save"),"class":"submit " + (attrs.new_rec ? "" : "hidden")}]);
    }
    if ((! attrs.new_rec) && (iga=attrs.instance_get_actions)){
      contents.push(["div",{"class":"instanceActions"},$.map(iga,function(action){return [["a",{"class":"instanceAction "+action},action.humanize()]]})]);
    }
    frm.push(contents);
    if(!i.content){i.content=[];}
    i.content.unshift(frm);
    return ["div",{"class":"instanceContainer"},i.content];
  }
}
colTypes={
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
    hprops.name=id2name(hprops.id);
    hprops.value=props.value[0];
    props.type="text";
    props.value=props.value[1];
    props.id=props.id.replace(/_id$/,"");
    props.name=id2name(props.id);
    return [["input",hprops],["input",props]]
  }
}
function id2name(s) {
  parts=s.split('__');
  name=parts.shift();
  $.each(parts,function(i,part){name+='['+part+']'});
  return name;
}
