$(document).ready(function()
{
    ///////////////////////////////////////////////////////////////////////////// SETUP
    var RESTRICT_HIDE = 1, NAME_INDEX =PROPS_INDEX = 1;
    var RESTRICT_RO = 2, TYPE_INDEX= 2, RESTRICTIONS_INDEX = 2;
    var VALUE_INDEX = 3;
    var RESTRICT_REQ = 4;
    var nodeTypes =
    {
        "link": function(r)
        {
            var link = ["a", {"href": r.attrs.url}, r.attrs.title];
            if (r.attrs.deletable)
            {
                return ["div", {"class":"linkContainer"}, [link, ["input", {"class": "delete " + r.attrs.title, "type": "button", "value": "x"}]]];
            }
            else
            {
                return link;
            }
        },
        "msg": function(m)
        {
            return ["p", {"class":"message"}, m.contents];
        },
        "section": function(s)
        {
            var attrs = s.attrs;
            var nav = $.map(attrs.navigation, function(i){ return [["li", {}, [i]]]; });
            return [
                "div",
                {"class": "section", "id": attrs.name + "__section"},
                [
                    ["h1", {}, attrs.title],
                    ["div", {"class": "sectionDescription"}, attrs.description],
                    ["ul", {"id": attrs.name + "_navigation", "class": "navigation"}, nav],
                    ["div", {"class": "content"}, s.content]
                ]
            ];
        },
        "instance": function(i)
        {
            var frm, ctl, attrs = i.attrs;
            if (attrs.search)
            {
                attrs.new_rec = true;
                frm = ["form", {"action": attrs.url, "method": "get", "class": "search"}];
            }
            else
            {
                frm = ["form", {"action": attrs.url, "method": "post", "class": attrs.name + "Instance instance"}];
            }
            var contents = attrs.description ? [["div", {"class": "form_description"}, attrs.description]] : [];
            if (!attrs.new_rec)
            {
                frm[1].action += "/" + attrs.schema[0][VALUE_INDEX];
                contents.push(["input", {"type": "hidden", "name": "_method", "value": "put"}]);
            }
            contents.push($.map(attrs.schema, function(col, i)
            {
                var props = {"id": attrs.name + "__" + col[1]};
                props.name = id2name(props.id);
                props.value = col[VALUE_INDEX] || "";
                if (col[RESTRICTIONS_INDEX] & RESTRICT_HIDE)
                {
                    if (props.value.constructor == Array) { props.value = props.value[0]; }  // many_to_one
                    props.type = "hidden";
                    return [["input", props]];
                }
                else
                {
                    if (!attrs.new_rec) { props["class"] = "hidden "; } // hide the actual controls in existing records
                    if (col[RESTRICTIONS_INDEX] & RESTRICT_RO)
                    {
                        delete props.name;
                        var v = props.value;
                        delete props.value;
                        // ugly as all fucking shit.  Will suffice for now.
                        // if(col[0] == "clob"){ v = $.map(v.split("\n"), function(p){ return [["p", {}, p]]; }); }
                        if (col[0] == "clob") { v = $('<div>' + v + '</div>'); }
                        ctl = ["div", props, v];
                    }
                    else
                    {
                        if (colTypes[col[0]])
                        {
                            ctl = colTypes[col[0]](props);
                        }
                        else
                        {
                            props["type"] = 'text';
                            props["class"] || (props["class"] = "");
                            props["class"] += col[0];
                            ctl = ["input", props];
                        }
                        if (!attrs.new_rec)
                        {
                            var show_val;
                            if (col[0] == "image")
                            {
                                show_val = ["img", {"src": ctl[1].value}];
                            }
                            else if (col[0] == "clob")
                            {
                                // ugly as all fucking shit.  Will suffice for now.
                                // show_val = $.map(col[VALUE_INDEX].split("\n"), function(p){ return [["p",{},p]]; })
                                show_val = $('<div>' + col[VALUE_INDEX] + '</div>');
                            }
                            else
                            {
                                show_val = ctl[1].value || ctl[2]; //textarea value
                            }
                            ctl = ["div", {"class": "editable col"}, [ctl, ["span", {}, show_val]]];
                        }
                    }
                    return [["div", {"class": props.id + "ColContainer colContainer"}, [["label", {"for": props.id}, col[1].humanize() + ":"], ctl]]];
                }
            }));
            if (attrs.search)
            {
                contents.push(["input", {"type": "submit", "value": "Search"}]);
            }
            else
            {
                contents.push(["input", {"type": "submit", "value": (attrs.url == "login" ? "login" : "save"), "class": "submit " + (attrs.new_rec ? "" : "hidden")}]);
            }
            if ((!attrs.new_rec) && (attrs.get_actions))
            {
                contents.push(
                    [
                        "div",
                        {"class": "instanceActions"},
                        $.map(attrs.get_actions, function(action)
                        {
                            return [["a", {"class": "instanceAction " + action}, action.humanize()]];
                        })
                    ]
                );
            }
            frm.push(contents);
            if (!i.content) { i.content=[]; }
            i.content.unshift(frm);
            return ["div", {"class": "instanceContainer"}, i.content];
        }
    };

    var colTypes =
    {
        "password": function(props)
        {
            props.type = "password";
            return ["input", props];
        },
        "clob": function(props)
        {
            var v = props.value;
            delete props.value;
            return ["textarea", props, v];
        },
        "image": function(props)
        {
            props.type = "file";
            return["input", props];
        }
    };

    function navClick()
    {
        $.get(this.href, "", getDisplayFunc($(this).closest('.section').children('.content')));
        return false;
    }

    function formSubmit()
    {
        // TEMPORARY
        if (this.action.match(/login$/))
        {
            $.ajax({"url": "/menu", "username": $('#login__name').val(), "password": $('#login__password').val(), "success": getDisplayFunc('body')});
        }
        else
        {
            $(this).find(".errorMsg").remove();
            $(this).find(".errorCol").removeClass("errorCol");
            $(this).ajaxSubmit({"success": getDisplayFunc($(this).closest(".instanceContainer"), "replaceWith")});
        }
        return false;
    }

    function toggleColStat()
    {
        $(this).closest('form').children(":submit").appendTo(this);
        $(this).children("input, span, textarea").toggleClass("hidden");
        $(this).toggleClass("editable editing");
        if ($(this).hasClass("editing"))
        {
            $(this).children("input").focus();
        }
    }

    function colEditKeypress(e)
    {
        // someone hit 'escape'
        if (e.keyCode == 27)
        {
            toggleColStat.apply($(this).closest(".editing"));
        }
    }

    function instanceActionClick()
    {
        $.get($(this).closest(".instance").attr("action") + '/' + $(this).attr('class').replace(/.* /,""), "", getDisplayFunc($(this).closest('.instance'),"after"));
        return false;
    }

    function deleteResource()
    {
        LOG(0, "Called deleteResource, but not yet implemented");
    }

    function getDisplayFunc(target, func)
    {
        if (!func) { func = "html"; }
        return function(json) { $(target)[func](json.toDom()); };
    }

    function showError(e, r, s)
    {
        $('body').trigger('waitEventEnded');
        try
        {
            var errArr = JSON.parse(r.responseText);
            var rn = s.url.replace(/\//g, '');
            if(errArr[PROPS_INDEX].error_type == 'validation')
            {
                $.each(errArr[PROPS_INDEX].error_details, function(col, msg)
                {
                    $("." + rn + "Instance #" + rn + "__" + col).addClass('errorCol');
                    $("." + rn + "Instance ." + rn + "__" + col + "ColContainer").append(["p", {"class": "errorMsg"}, col + " " + msg].toDom());
                    $("." + rn + "Instance #" + rn + "__" + col).focus();
                });
            }
        }
        catch (err)
        {
            // in case it's not JSON
            LOG(0, r.responseText, err);
        };
    }

    function id2name(s)
    {
        var parts = s.split('__');
        var name = parts.shift();
        $.each(parts, function(i, part) { name += '[' + part + ']'; });
        return name;
    }

    ///////////////////////////////////////////////////////////////////////////// EVENTS
    $('body').bind('waitEventStarted', function(){ $('body').css('cursor', 'wait'); });
    $('body').bind('waitEventEnded', function(){ $('body').css('cursor', 'default'); });

    ///////////////////////////////////////////////////////////////////////////// UTILITIES
    // console output
    if (!window.console)
    {
    	window.console =
    	{
    		log: function(message)
    		{
    			alert(message);
    		}
    	};
    }
    var LOGLEVEL = 0; // everything
    function LOG()
    {
    	var level = arguments[0];
    	if (level >= LOGLEVEL)
    	{
    		for (var i = 1, j = arguments.length; i < j; i++)
    		{
    			window.console.log(arguments[i]);
    		}
    	}
    }

    String.prototype.humanize = function()
    {
        return $.map(this.split('_'), function(w)
        {
            return w[0].toUpperCase() + w.slice(1);
        }).join(' ');
    };

    String.prototype.toDom = function()
    {
        return document.createTextNode(this);
    };

    Number.prototype.toDom = String.prototype.toDom;

    Array.prototype.isNodeSpec = function()
    {
        return this[0] && this[0].constructor == String && this[1] && this[1].constructor == Object;
    };

    Array.prototype.toDom = function()
    {
        if (this.isNodeSpec())
        {
            // this array is in normal form so set some local state variables
            this.nodeType = this[0];
            this.attrs = this[1];
            this.content = this[2];
            if (nodeTypes[this.nodeType])
            {
                return nodeTypes[this.nodeType](this).toDom();
            }
            else
            {
                var dom = $(document.createElement(this.nodeType)).attr(this.attrs)[0];
                if (this.content)
                {
                    $(dom).append(this.content.toDom ? this.content.toDom() : this.content);
                }
                return dom;
            }
        }
        else
        {
            return $.map(this, function(e) {e || (e = ""); return e.toDom ? e.toDom() : e; });
        }
    };

    function initialize()
    {
        getDisplayFunc('body')(_jamaica_json);
        $.ajaxSetup({"dataType": "json"});
        $('body').ajaxStart(function(){$('body').trigger('waitEventStarted');});
        $('body').ajaxComplete(function(){$('body').trigger('waitEventEnded');});
        $('body').ajaxError(showError);
        $('ul.navigation li a').live('click', navClick);
        $('form.instance, form.search').live('submit', formSubmit);
        $('.editable').live('click', toggleColStat);
        $('.editing input').live('keypress', colEditKeypress);
        $('a.instanceAction').live('click', instanceActionClick);
        $('.urlContainer .delete').live('click', deleteResource);
    }

    // Here is where the lifecycle begins:
    initialize();
});

