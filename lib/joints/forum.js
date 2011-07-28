$(function(){
  $("body").ajaxComplete(function(){
    $(".postInstance,.private_messageInstance").parent().not('.collapsible').prepend(["a",{"href":"#","class":"expandCollapse"},"collapse"].toDom()).prepend(["a",{"href":"#","class":"expandCollapseAll"},"collapse from here"].toDom());
    $(".postInstance,.private_messageInstance").parent().not('.collapsible').addClass('collapsible');
  });
  $(".expandCollapse").live('click',collapseExpand);
  $(".expandCollapseAll").live('click',collapseExpandAll);
});

function collapseExpand() {
  $(this).closest('.collapsible').toggleClass('collapsed').toggleClass('expanded');
  $(this).html($(this).html()=='collapse' ? 'expand' : 'collapse');
  return false;
}
function collapseExpandAll() {
  var affected=$(this).closest('.collapsible').find('.collapsible').andSelf();
  if ($(this).html().match(/collapse/)){
    affected.addClass('collapsed').removeClass('expanded').find('.expandCollapse,.expandCollapseAll').each(function(){$(this).html($(this).html().replace(/collapse/,'expand'))});
  } else {
    affected.removeClass('collapsed').addClass('expanded').find('.expandCollapse,.expandCollapseAll').each(function(){$(this).html($(this).html().replace(/expand/,'collapse'))});
  }
  return false;
}
