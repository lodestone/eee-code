function (doc) {
  if (doc['type'] == 'Recipe' && doc['published']) {
    emit(doc['date'], {'id':doc['_id'],'title':doc['title'],'date':doc['date']});
  }
}
