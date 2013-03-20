/**
 * @author slangen
 */
//ADDED
var linkFieldCount = 1;

function addLinkField() {
  var fields = $('links_fields');
  if (fields.childElements().length >= 10) return false;
  fileFieldCount++;
  var s = new Element('span');
  s.update(fields.down('span').innerHTML);
  s.down('input.file').name = "links[" + fileFieldCount + "][fileaddress]";
  s.down('input.description').name = "links[" + fileFieldCount + "][description]";
  fields.appendChild(s);
}

function removeLinkField(el) {
  var fields = $('links_fields');
  var s = Element.up(el, 'span');
  if (fields.childElements().length > 1) {
    s.remove();
  } else {
    s.update(s.innerHTML);
  }
}
