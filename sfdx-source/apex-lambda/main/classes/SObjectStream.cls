public with sharing virtual class SObjectStream implements Iterator<SObject> {
    
	protected Iterator<SObject> recordsIterator;

	public static SObjectStream of(Iterable<SObject> records) {
		return new SObjectStream(records.iterator());
	}

	protected SObjectStream(Iterator<SObject> recordsIterator) {
		this.recordsIterator = recordsIterator;
	}

	public SObjectStream filter(SObjectPredicate predicate) {
		return new SObjectFilteringStream(this, predicate);
	}

	public SObjectStream remove(SObjectPredicate predicate) {
		return new SObjectRemovingStream(this, predicate);
	}

	public SObjectStream mapAll(SObjectToSObjectFunction fn) {
		return new SObjectMappingStream(this, fn);
	}

	public virtual Boolean hasNext() {
		return recordsIterator.hasNext();
	}

	public virtual SObject next() {
		return recordsIterator.next();
	}

	public List<SObject> toList() {
		List<SObject> records = new List<SObject>();
		while (hasNext()) {
			records.add(next());
		}
		return records;
	}
}