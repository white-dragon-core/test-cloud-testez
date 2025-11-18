/**
 * Extended matchers for TestEZ Expectation
 * Provides additional assertion methods beyond the core matchers
 */
interface CustomMatchers {
	// Deep comparison
	/**
	 * Assert that the expectation value is deeply equal to another value.
	 * Recursively compares table contents.
	 */
	deepEqual: (otherValue: unknown) => this;

	// String/Table inclusion
	/**
	 * Assert that a string contains a substring or a table contains an element.
	 */
	include: (searchValue: unknown) => this;

	/**
	 * Alias for include()
	 */
	contain: (searchValue: unknown) => this;

	// Length checking
	/**
	 * Assert that a string or table has the expected length.
	 */
	lengthOf: (expectedLength: number) => this;

	/**
	 * Assert that a string or table is empty.
	 */
	empty: () => this;

	// Numeric comparisons
	/**
	 * Assert that a number is greater than another number.
	 */
	greaterThan: (compareValue: number) => this;

	/**
	 * Alias for greaterThan()
	 */
	above: (compareValue: number) => this;

	/**
	 * Assert that a number is less than another number.
	 */
	lessThan: (compareValue: number) => this;

	/**
	 * Alias for lessThan()
	 */
	below: (compareValue: number) => this;

	/**
	 * Assert that a number is greater than or equal to another number.
	 */
	greaterThanOrEqual: (compareValue: number) => this;

	/**
	 * Alias for greaterThanOrEqual()
	 */
	atLeast: (compareValue: number) => this;

	/**
	 * Assert that a number is less than or equal to another number.
	 */
	lessThanOrEqual: (compareValue: number) => this;

	/**
	 * Alias for lessThanOrEqual()
	 */
	atMost: (compareValue: number) => this;

	/**
	 * Assert that a number is within a range (inclusive).
	 */
	within: (min: number, max: number) => this;

	/**
	 * Assert that a number is NaN (Not a Number).
	 */
	NaN: () => this;

	// String matching
	/**
	 * Assert that a string matches a Lua pattern.
	 */
	match: (pattern: string) => this;

	/**
	 * Assert that a string starts with a prefix.
	 */
	startWith: (prefix: string) => this;

	/**
	 * Assert that a string ends with a suffix.
	 */
	endWith: (suffix: string) => this;

	// Table/Property checking
	/**
	 * Assert that a table has a property, optionally with a specific value.
	 */
	property: (propertyName: string | number, expectedValue?: unknown) => this;

	/**
	 * Assert that a table has specific keys.
	 */
	keys: (...keys: Array<string | number>) => this;

	/**
	 * Assert that an array contains all members of another array (unordered).
	 */
	members: (expectedMembers: unknown[]) => this;

	// Value checking
	/**
	 * Assert that a value is one of the values in a list.
	 */
	oneOf: (list: unknown[]) => this;

	/**
	 * Assert that a value is nil.
	 */
	nilValue: () => this;

	/**
	 * Assert that a value is exactly true (not just truthy).
	 */
	trueValue: () => this;

	/**
	 * Assert that a value is exactly false (not just falsy).
	 */
	falseValue: () => this;
}

interface Expectation<T> {
	// LINGUISTIC NO-OPS
	/** A linguistic no-op */
	readonly to: Expectation<T> & CustomMatchers;

	/** A linguistic no-op */
	readonly be: Expectation<T> & CustomMatchers;

	/** A linguistic no-op */
	readonly been: Expectation<T> & CustomMatchers;

	/** A linguistic no-op */
	readonly have: Expectation<T> & CustomMatchers;

	/** A linguistic no-op */
	readonly was: Expectation<T> & CustomMatchers;

	/** A linguistic no-op */
	readonly at: Expectation<T> & CustomMatchers;

	// LINGUISTIC OPS
	/** Applies a never operation to the expectation */
	readonly never: Expectation<T> & CustomMatchers;

	// METHODS

	/**
	 * Assert that the expectation value is the given type.
	 * @param typeName The given type
	 * @returns If the assertion passes, returns reference to itself
	 */
	a: (typeName: ReturnType<typeof typeOf>) => Expectation<T>;

	/**
	 * Assert that the expectation value is the given type.
	 * @param typeName The given type
	 * @returns If the assertion passes, returns reference to itself
	 */
	an: (typeName: ReturnType<typeof typeOf>) => Expectation<T>;

	/**
	 * Assert that our expectation value is not `undefined`
	 * @returns If the assertion passes, returns reference to itself
	 */
	ok: () => Expectation<T>;

	/**
	 * Assert that our expectation value is equal to another value
	 * @param otherValue The other value
	 * @returns If the assertion passes, returns reference to itself
	 */
	equal: (otherValue: unknown) => Expectation<T>;

	/**
	 * Assert that our expectation value is equal to another value within some
	 * inclusive limit.
	 * @param otherValue The other value
	 * @param limit The inclusive limit (defaults to 1e-7)
	 * @returns If the assertion passes, returns reference to itself
	 */
	near: (this: Expectation<number>, otherValue: number, limit?: number) => Expectation<T>;

	/**
	 * Assert that our functoid expectation value throws an error when called
	 * @param search If passed, asserts that this substring is included in the error message
	 * @returns If the assertion passes, returns reference to itself
	 */
	throw: (this: Expectation<Callback>, search?: string) => Expectation<T>;
}

interface ExpectationConstructor {
	new <T>(value: T): Expectation<T> & CustomMatchers;
	/**
	 * Extend Expectation with custom matchers
	 */
	extend(matchers: Partial<CustomMatchers>): void;
}

declare const Expectation: ExpectationConstructor;
export = Expectation;
