@IsTest
public class DoubleCollectionTest {
	@IsTest
	static void testSum() {
		DoubleCollection c = new DoubleCollection(new List<Double>{100, 150});
		System.assertEquals(250, c.sum());
	}

	@IsTest
	static void testAverage() {
		DoubleCollection c = new DoubleCollection(new List<Double>{100, 150});
		System.assertEquals(125, c.average());
	}

	@IsTest
	static void testFilterWithObjectPredicate() {
		DoubleCollection c = new DoubleCollection(new List<Double>{null, 100, null, 150, null});
		List<Double> filtered = c.filter(ObjectPredicates.NotNull).asList();
		System.assertEquals(2, filtered.size());
		System.assertEquals(100, filtered[0]);
		System.assertEquals(150, filtered[1]);
	}

	private class IsGreaterThanTen implements DoublePredicate {
		public Boolean apply(Double d) {
			return d != null && d > 10;
		}
	} 

	@IsTest
	static void testFilterWithDoublePredicate() {
		DoubleCollection c = new DoubleCollection(new List<Double>{null, 20, 5, 23});
		List<Double> filtered = c.filter(new IsGreaterThanTen()).asList();
		System.assertEquals(2, filtered.size());
		System.assertEquals(20, filtered[0]);
		System.assertEquals(23, filtered[1]);
	}
}