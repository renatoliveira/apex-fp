# Lambda

Lambda brings functional programming to Salesforce!

The library consists of several classes which enable functional programming style list manipulations: `Filter`, `Pluck` and `GroupBy`.

# Documentation

- [`Filter`](#filter)
- [`Pluck`](#pluck)
- [`GroupBy`](#group-by)

Also read [Important notes on the type system in Apex](#type-system).

## `Filter`
<a name="filter"></a>

Filter is used to describe criteria to filter lists of sObject records. There are two available *types* of filters:

1. **field matching** filter
2. **object matching** filter

Each type has three possible *behaviours*:

1. `apply` selects matching elements from the list and returns them. The original list is not modified.
2. `applyLazy` does the same as apply but returns an `Iterable<sObject>` instead.
3. `extract` selects matching elements from the list and returns them. The matching elements are removed from the original list.

### Field matching filter

A field matching filter matches the objects in a list with using some of the available *criteria*:

* `equals(Object value)` (alias `eq`)
* `notEquals(Object value)` (alias `neq`)
* `lessThan(Object value)` (alias`lt`)
* `lessThanOrEquals(Object value)` (alias`leq`)
* `greaterThan(Object value)` (alias `gt`)
* `greaterThanOrEquals(Object value)` (alias`geq`)
* `isIn(Object setValue)`
* `isNotIn(Object setValue)` (alias `notIn`)
* `hasValue` (alias `notNull`)

The final filter can consist of any number of criteria added through the `also` method. Only those records that match *all* criteria are then returned.

#### Examples

Example of simple filtering. Accounts with annual revenue under 100,000 are returned when `Filter` is applied to a list.

```java
List<Account> lowRevenue = Filter.field(Account.AnnualRevenue).lessThanOrEquals(100000).apply(accounts);
```

Aliases can be used to shorten `Filter` queries. Instead of `greaterThanOrEquals`, one can also write `geq`.

```java
List<Account> highRevenue = Filter.field(Account.AnnualRevenue).geq(cutoff).apply(accounts);
```

Multiple criteria can be stringed together with `also` to form the full query:

```java
List<Account> filtered = Filter.field(Account.Name).equals('Ok').also(Account.AnnualRevenue).greaterThan(100000).apply(accounts);
```

Most criteria expect a primitive value to compare against. `isIn` and `isNotIn` instead expect a `Set` of one of the following types: `Boolean`, `Date`, `Decimal`, `Double`, `Id`, `Integer` or `String`. **Other types are not supported and will throw an exception**.

```java
List<Account> filtered = Filter.field(Account.Name).isIn(new Set<String>{'Foo', 'Bar'}).apply(accounts);
```

#### :warning: Limitations

Fields chosen for filtering must be available on the list which is filtered, otherwise a `System.SObjectException: SObject row was retrieved via SOQL without querying the requested field` exception can be thrown.

Filtering query is dynamic and cannot be type-checked at compile-time.

### Object matching filter

If we're just looking for strict equality filtering, object matching filter type allows us to define a “prototype” object to match list objects against. If all of the fields on the prototype object match the fields on the list object, the list object is matched.

The matching check is performed only on those fields that are set on the prototype object. Other fields are ignored.

#### Examples

To find all accounts which have `Description` set to “Test”, we can use a single account with `Description` set to “Test” and use it match other accounts. This account serves as a “prototype” object to match against.

```java
List<Account> accountsToFilter = ...
Account prototype = new Account(Description = 'Test');
List<Account> testAccounts = Filter.match(prototype).apply(accountsToFilter);
```

If we're looking for accounts that have both a “Test” description **and** have an annual revenue of exactly 50,000,000, we can again use a “prototype” with such properties:

```java
Account prototype = new Account(
    Description = 'Test description',
    AnnualRevenue = 50000000
);
List<Account> matchingAccounts = Filter.match(prototype).apply(accountsToFilter);
```

Object matching filter can be easier to read when there are multiple equality criteria then an equivalent field matching filter. Compare the above with:

```java
List<Account> matchingAccounts = Filter.field(Account.Description).equals('Test').also(Account.AnnualRevenue).equals('50000000').apply(accountsToFilter);
```

#### :warning: Limitations

Fields that are present on the *prototype* object must also be available on the list which is filtered, otherwise a `System.SObjectException: SObject row was retrieved via SOQL without querying the requested field` exception will be thrown.

## `Pluck`
<a name="pluck"></a>

* `booleans(List<SObject>, Schema.SObjectField)`
* `dates(List<SObject>, Schema.SObjectField)`
* `decimals(List<SObject>, Schema.SObjectField)`
* `ids(List<SObject>)`
* `ids(List<SObject>, Schema.SObjectField)`
* `strings(List<SObject>, Schema.SObjectField)`

Pluck allows you to pluck values of a field from a list of sObjects into a new list. This pattern is used commonly when a field is used as a criteria for further programming logic. For example:

```java
List<Account> accounts = [Select Name,... from Account where ...];

List<String> names = new List<String>();
for (Account a : accounts) {
    names.add(a.Name);
}
// do something with names
```

Plucking code can be replaced with a declarative call to the appropriate `Pluck` method:

```java
List<String> names = Pluck.strings(accounts, Account.Name);
```

The `ids` method is returns a set instead of a list for convenience, because `Id` values are rarely required in order. If they are, `strings` can be used on `Id` fields as well.

```java
Set<Id> ownerIds = Pluck.ids(accounts, Account.OwnerId);
```

There is a shorthand version which doesn’t require a `Schema.SObjectField` parameter. Instead, it defaults to the system `Id` field:

```java
Set<Id> accountIds = Pluck.ids(accounts);
// equivalent to Set<Id> accountIds = Pluck.ids(accounts, Account.Id);
```

## `GroupBy`
<a name="group-by"></a>

* `booleans(List<SObject>, Schema.SObjectField)`
* `dates(List<SObject>, Schema.SObjectField)`
* `decimals(List<SObject>, Schema.SObjectField)`
* `ids(List<SObject>, Schema.SObjectField)`
* `strings(List<SObject>, Schema.SObjectField)`

Another common pattern is grouping objects by values on some field. It's so common that Apex provides support for grouping by `Id` fields on sObjects out of the box:

```java
List<Account> accounts = [Select Name,... from Account where ...];
Map<Id, Account> accountsById = new Map<Id, Account>(accounts);
```

`GroupBy` fills the gap for all other fields:

```java
Map<String, List<Account>> accountsByName = GroupBy.strings(accounts, Account.Name);
```

### :warning: Limitations

Be extra careful, the **type system will NOT warn you if you use the wrong subtype of `sObject`!** [Important notes on the type system in Apex](#type-system) section explains why.

```java
// this compiles
Map<String, List<Account>> accountsByName = GroupBy.strings(accounts, Account.Name);
// this compiles as well!!!???
Map<String, List<User>> accountsByName = GroupBy.strings(accounts, Account.Name);
Map<String, List<Opportunity>> accountsByName = GroupBy.strings(accounts, Account.Name);
```

## Important notes on the type system in Apex
<a name="type-system"></a>

Type system for `SObject` types in Apex does not work as one would would naturally expect. Apex allows assignment of `SObject` collection to its “subclass”, and the other way around:

```java
List<SObject> objects = new List<SObject>();
List<Account> accounts = objects; // compiles!

List<Account> accounts = new List<Account>();
List<SObject> objects = accounts; // compiles as well!
```

An `SObject` list is an instance of any `SObject` “subclass” list!

```java
List<SObject> objects = new List<SObject>();
System.debug(objects instanceof List<Account>); // true
System.debug(objects instanceof List<Opportunity>); // true
System.debug(objects instanceof List<Custom_Object__c>); // true
```

Lambda classes usually return an `SObject` list, which can be then assigned to a specific `SObject` “subclass” list, like `Account`. While this works fine most of the time, `instanceof` can provide unexpected results:

```java
List<Account> accounts = Filter...
// accounts points to a List<SObject> returned from Filter

Boolean isOpportunities = accounts instanceof List<Opportunity>;
// isOpportunities is true!!!???
```

When you want to be sure that your `List<SomeObject>` will behave like `List<SomeObject>` in all situations, you could explicitly cast to that. Example:

```java
List<SomeObject> someList = (List<SomeObject>) Filter. ...
```

However, Apex does not allow you to cast from `Map<String, List<SObject>>` to a `Map<String, List<Account>>`.

```java
// this doesn't compile!!!
Map<String, List<Account>> accountsByName = (Map<String, List<Account>>) GroupBy.strings(accounts, Account.Name);
```

`Filter` and `GroupBy` therefore provide overloaded methods in which the concrete type of the list can be passed in as well. When this is done, the returned `List` or `Map` are of the correct concrete type instead of generic `SObject` collection type:

```java
List<Account> filteredAccounts = Filter.field(...).apply(allAccounts, List<Account>.class);
// List<Account> returned!

Map<String, List<Account>> accountsByName = GroupBy.strings(allAccounts, Account.Name, List<Account>.class);
// Map<String, List<Account>> returned!
```