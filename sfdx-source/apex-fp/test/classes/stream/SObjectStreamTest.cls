@IsTest
public class SObjectStreamTest {
	@IsTest
	public static void testFilter() {
		List<Account> accounts = new List<Account>{
			new Account(Name = 'Ok', AnnualRevenue = 100),
			new Account(Name = 'Wrong', AnnualRevenue = 60),
			new Account(Name = 'Ok', AnnualRevenue = 150),
			new Account(Name = 'Wrong', AnnualRevenue = 150)
		};
		Iterator<SObject> iter = SObjectStream.of(accounts).filter(Match.field(Account.Name).equals('Ok'));
		
		List<SObject> filtered = new List<SObject>();
		while (iter.hasNext()) {
			filtered.add(iter.next());
		}
		System.assertEquals(2, filtered.size());
		System.assertEquals(accounts[0], filtered[0]);
		System.assertEquals(accounts[2], filtered[1]);
	}

	@IsTest
	public static void testFilterChaining() {
		List<Account> accounts = new List<Account>{
			new Account(Name = 'Ok', AnnualRevenue = 100),
			new Account(Name = 'Wrong', AnnualRevenue = 60),
			new Account(Name = 'Ok', AnnualRevenue = 150),
			new Account(Name = 'Wrong', AnnualRevenue = 150)
		};
		Iterator<SObject> iter = SObjectStream.of(accounts).filter(Match.field(Account.Name).equals('Ok')).filter(Match.field(Account.AnnualRevenue).equals(150));
		
		List<SObject> filtered = new List<SObject>();
		while (iter.hasNext()) {
			filtered.add(iter.next());
		}
		System.assertEquals(1, filtered.size());
		System.assertEquals(accounts[2], filtered[0]);
	}

	@IsTest
	public static void testRemove() {
		List<Account> accounts = new List<Account>{
			new Account(Name = 'Ok', AnnualRevenue = 100),
			new Account(Name = 'Wrong', AnnualRevenue = 60),
			new Account(Name = 'Ok', AnnualRevenue = 150),
			new Account(Name = 'Wrong', AnnualRevenue = 150)
		};
		Iterator<SObject> iter = SObjectStream.of(accounts).remove(Match.field(Account.Name).equals('Wrong'));		
		
		List<SObject> filtered = new List<SObject>();
		while (iter.hasNext()) {
			filtered.add(iter.next());
		}
		
		System.assertEquals(2, filtered.size());
		System.assertEquals(accounts[0], filtered[0]);
		System.assertEquals(accounts[2], filtered[1]);
	}

	@IsTest
	public static void testMapAll() {
		List<Account> accounts = new List<Account>{
			new Account(Name = 'Ok'),
			new Account(Name = 'Wrong'),
			new Account(Name = 'Ok'),
			new Account(Name = 'Wrong')
		};
		Iterator<SObject> iter = SObjectStream.of(accounts).mapAll(CopyFields.fromRecord(new Account(AnnualRevenue = 100)));		
		
		List<SObject> mapped = new List<SObject>();
		while (iter.hasNext()) {
			mapped.add(iter.next());
		}
		
		System.assertEquals(4, mapped.size());
		for (SObject record : mapped) {
			System.assertEquals(100, ((Account) record).AnnualRevenue);
		}
	}

	@IsTest
	public static void testMapSome() {
		List<Account> accounts = new List<Account>{
			new Account(Name = 'Ok'),
			new Account(Name = 'Wrong'),
			new Account(Name = 'Ok'),
			new Account(Name = 'Wrong')
		};
		Iterator<SObject> iter = SObjectStream.of(accounts).mapSome(Match.field(Account.Name).equals('Ok'), CopyFields.fromRecord(new Account(AnnualRevenue = 100)));
		
		List<SObject> mapped = new List<SObject>();
		while (iter.hasNext()) {
			mapped.add(iter.next());
		}
		
		System.assertEquals(4, mapped.size());
		for (SObject record : mapped) {
			Account a = (Account) record;
			if (a.Name == 'Ok') {
				System.assertEquals(100, a.AnnualRevenue);
			} else {
				System.assertEquals(null, a.AnnualRevenue);
			}
		}
	}
}