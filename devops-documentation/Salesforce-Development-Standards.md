# Development Standards for Salesforce applications and packages

Salesforce application and package development is a complicated process with many security considerations and pitfalls to avoid. This document is meant to be a collection of lessons learned along with the general style we should adhere to when creating metadata and writing code for an application or package in Salesforce. This is meant to be a living document and should evolve as Salesforce changes and as we become a more mature team. Developers are expected to follow the standards in this document and they will be enforced through peer reviews.

## Packaging

- The `manifest/package.xml` file should not contain wildcards and should explicitly be updated to include every piece of metadata we want to release or package to ensure no unintended metadata is included. No standard Salesforce objects or fields should be added to the package.xml since we can not package them.

- It's good to periodically upgrade to the latest publicly available `API Version` of classes, triggers, pages and lightning components. There is speculation that using really old API Versions can cause performance issues. When creating a new class or trigger or LWC, make sure to use an API version that is available to all Salesforce orgs - don't use a pre-release API version.

## Objects and Fields

- It's best to use a `Lookup` relationship instead of `Master Detail` for packaged objects. Master Detail relationships lock the parent record longer than a lookup and can cause serious performance problems and [record locking exceptions](http://resources.docs.salesforce.com/rel1/doc/en-us/static/pdf/SF_Record-Locking-Cheatsheet_web.pdf) that can't be handled. This is especially true for commonly used standard objects such as `Account`, `Contact`, `Case` and `Opportunity`.

- All sensitive data should be stored in `encrypted` fields.

- You should mark text fields that may be used in queries or searches as `External ID` so the field is indexed by Salesforce. You cannot change a field to be indexed once it has been packaged and released.

## Custom Metadata Types, Custom Settings and Custom Labels

- Try to use `Custom Metadata Types` over `Custom Settings` since we can package Custom Metadata Type records.

- If using a Custom Setting, use `Hierarchy` over `List` in case settings need to be different by Profile or User.

- `Custom Settings` that are inserted/updated/deleted need to have their object and field access checked for the security review.

- Use `Custom Labels` for most text in displayed to customers in case a value need to be overridden for a customer or translated to different languages.

## Permission Sets

- Permission Sets are the preferred way to assign the correct permissions to Salesforce Users of our package.

- Be sure to update our packaged permission sets for any of our Custom Object, Custom Field, Custom Setting, Custom Metadata Type or VisualForce page that is added.

- Don't package permissions for any standard Salesforce object or field - it could inadvertently give access to a user that shouldn't have it and get us in trouble with a customer.

- Do not set `View All` and `Modify All` to true for objects in our Permission Sets - it prevents customers from using sharing settings with our objects.

## Naming Convention

### Objects

- When naming an object, try to keep the name short and simple. Be sure to include a Description for each custom object.

- Do not use the same name as any existing standard Salesforce object or other packaged object we depend on - it causes confusion in reports and setup because the same name shows up twice and users can't tell which is which.

### Fields

- When naming a field, leave spaces between words, capitalize each word and do not use underscores or dashes in labels.

- Be sure to enter the purpose of the field in the description and avoid technical jargon.

- Be consistent with field naming conventions for all fields and use positive terms instead of negatives. `Is Feature Enabled` should be used instead of `Is Feature Disabled`.

### Apex

- Our class and trigger names should be `Object + Action + Controller/Batch/Service/Selector/Trigger`.

- All words in a class name should be capitalized (PascalCase) and should not contain underscores.

- We want to have a corresponding test class that ends with Test so make sure the class name is at most 36 characters long so it's corresponding test class can end with `Test`. Examples are:

  - `CaseUpdateController` and `CaseUpdateControllerTest`

  - `CaseService` and `CaseServiceTest`

  - `CaseSelector` and `CaseSelectorTest`

  - `CaseUpdateStatusBatch` and `CaseUpdateStatusBatchTest`

### LWC & VisualForce

- LWC and VisualForce component names should use camelCase and must start with a lowercase letter.

- The Name should include the object and action. It can also include a prefix to group related components together.

- Do not use underscores in a component name.

- VisualForce also have a 40 character limit for the Name and Lightning Components have an 80 character limit for Name.

## Salesforce Secure Coding Guidelines

This is a great section in the ISV Guide that documents common violations to avoid. All developers should read and be familiar with these violations to avoid failing the security review.
- https://developer.salesforce.com/docs/atlas.en-us.packagingGuide.meta/packagingGuide/secure_code_prevent_violations.htm 

Here are some great Secure App Trailheads all developers should take:

- [Secure Client-Side Development](https://trailhead.salesforce.com/en/content/learn/modules/secure-clientside-development?trail_id=security_developer)

- [Secure Server-Side Development](https://trailhead.salesforce.com/en/content/learn/modules/secure-serverside-development?trail_id=security_developer)

- [Secure Secrets Storage](https://trailhead.salesforce.com/en/content/learn/modules/secure-secrets-storage?trail_id=security_developer)

## Apex Development

### Trigger Architecture

All trigger logic for an object will use the
[Domain Layer - Apex Enterprise Patterns](https://github.com/apex-enterprise-patterns/fflib-apex-common#this-library)
which groups all trigger handling into 1 class per object. You can download and implement the [trigger handler along with a working example from the UST Solution Hub](https://solutionhub.ustpace.com/#/assets/465/version/475).

Here are Trailheads that discuss the `Domain`, `Selector` and `Service` Apex Enterprise Patterns that have become standards for managed package development:

- [Apex Enterprise Patterns: Domain & Selector Layers](https://trailhead.salesforce.com/content/learn/modules/apex_patterns_dsl)

- [Apex Enterprise Patterns: Service Layer](https://trailhead.salesforce.com/en/content/learn/modules/apex_patterns_sl)

These patterns help us achieve these trigger dev standards:

- Only one trigger per object.

- There is no logic in the trigger - all logic should reside in a trigger handler class.

- The trigger handler is context-specific and bulkified to handle hundreds of records at a time.

- The trigger handler prevents recursion.

- Updates to the current record in context should be done before insert/update context to avoid extra DML.

- Triggers are re-invoked on record update or record insert actions from flows, workflows and process builders. For this reason we should not have both triggers and flows defined for an object. Pick one [(preferably triggers)](Salesforce-Development-Standards.md#flows-and-workflows) to keep things fast.

### Database Queries and DML in Apex

- Include the `with SECURITY_ENFORCED` statement **IN ALL QUERIES**! This is the easiest way to check Object and Field level access to avoid failing the security review.

- Don't write SOQL without a `where` or `limit` clause. Some customer may have millions of records and these risky queries will cause limit exceptions.

- No SOQL or DML statements inside loops - these will run slowly and probably cause limit exceptions.

- [Prevent SOQL Injections](https://developer.salesforce.com/docs/atlas.en-us.packagingGuide.meta/packagingGuide/secure_code_violation_soql_injection.htm) by sanitized client editable SOQL variables with the `String.escapeSingleQuotes` method.

- Use [SOQL For Loops instead of Standard SOQL Queries](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/langCon_apex_loops_for_SOQL.htm) for better performance.

- Limit the number of SOQL statements by using relationships to query related objects/data.

- You can use [Access.cls](https://solutionhub.ustpace.com/#/assets/455/version/465) to check CRUD permissions on objects and fields before making database calls. These access checks are required to pass the security review.

### Managed Package Apex Coding Guidelines

- Always include `with sharing`, `inherited sharing` or `without sharing` in class definitions (not needed in test classes). We should avoid `without sharing` in case a customer wants to enable sharing rules on some of our package objects.

- `Named Credentials` should be used to store credentials needed to connect to APIs.

- We should keep the package `Install Handler` class as simple as possible since it runs as a "ghost" user with limited permissions. All that should be done in the install handler is simple data loads. Anything more complicated like scheduling batches or API callouts should be done from a custom `App Setup` LWC.

- Utilize Maps instead of nested for loops. Nested for loops are very slow.

- Use `try - catch` blocks to trap exceptions throughout the application. Exceptions should be displayed to end users if possible or else logged to records so they can be reviewed and fixed. We have a [Logging Service](https://solutionhub.ustpace.com/#/assets/446/version/456) built into the application that should be used when logging exceptions.

- Methods that only need to be called within one class should be marked as private. This makes refactoring easier since a developer can easily determine that a private method is not referenced outside the class.

- Use curly braces `{ }` in all `for`, `while`, `if` and `else` statements. It's not always necessary but is way better for avoiding bugs and for readability.

- Don't duplicate code. If the method is generic and can be called from multiple classes, add it to our `Utils` class.

- Use `String.isBlank` or `String.isNotBlank` instead of `== null` and `== ''`. It covers both null and blank checks. It can also be used to evaluate Id fields.

- `Batch` and `Scheduler` Jobs - implement scheduler interface in same class as batch code instead of in a separate Scheduler class. This cuts down the number of classes down to 2 instead of 4 since these also need test classes.

- Do not use `global` classes and methods unless we truly want to expose the class/methods to our customers. We can't delete global classes so use this with caution.

- Limit using the `@future` annotation on methods. These future methods will throw an exception if triggered from a Batch job. We should use the [Queueable Interface](https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_class_System_Queueable.htm) instead.

- Code should includes null checks and logic to prevent or handle null pointer exceptions.

- Bulkify Service methods to be able to process hundreds of records at a time.

- Do not hard code record IDs in Apex - it will fail the security review.

### Apex Tests

- Tests should be meaningful and cover positive (happy) and negative (sad) scenarios.

- Strive for at least 90% test coverage for each class. 100% is even better 😃.

- Test bulk scenarios to make sure there are no limit exceptions and that performance is good.

- All test methods must contain at least one `assertion` to make sure we are getting code coverage and that our apex classes are returning the expected results. Test methods without an assertion will fail the security review.

- Use the `@isTest` decorator above each test method instead of the `testmethod` method declaration.

- Put the test setup method as the first method in the test class before all test methods. Also, always utilize `@TestSetup` methods for setting up test data that will be used in at least 75% of all test methods.

- Have tests set `System.runAs` to a User that has one of our permission sets assigned.

- Tests must be in their own Class and should never use the `@SeeAllData` annotation.

- Use `Test.startTest()` and `Test.stopTest()` [when testing asynchronous calls which causes asynchronous processes to run synchronously.](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_testing_tools_start_stop_test.htm).

- Use `mock` testing framework to test web services and API callouts.

## LWC vs Aura vs VisualForce

- Lightning Web Components (LWC) should always be used over Aura components. Salesforce recommends LWC over Aura and may even start to deprecate Aura in the near future. [Here are the benefits of LWC vs Aura.](https://www.jadeglobal.com/blog/benefits-lightning-web-components-over-aura-lightning-components)

- Be careful with the `@api` annotation in LWC - these can't be removed or changed once packaged.

- Don't package components that require the `Locker Service` to be disabled. These components will fail the security review.

- All `JavaScript` used or referenced in LWC or VisualForce must be stored as a `Static Resource`. Any JavaScript loaded from an external source will fail the security review.

- Lightning Web Components should also be chosen over VisualForce for most instances but VisualForce can be used if it's the best fit for the requirement.

- Never put an action attribute in the VisualForce page tag. The security review fails these as a risk for `Cross-Site Request Forgery` attacks.

## Flows and Workflows

- We should minimize Flows that we package since they do not contain unit tests like Apex. Flows are fine for simple workflows but should be avoided for complex processes.

- Flows can also cause triggers to re-fire and slow down processes. Flows should not be used along with triggers for record updates.

- Active Flows can also cause package upgrade and uninstall issues that are hard to debug and fix.

- Avoid packaging Workflow rules and Process Builder metadata - Salesforce announced these will be deprecated - https://admin.salesforce.com/blog/2021/go-with-the-flow-whats-happening-with-workflow-rules-and-process-builder

## How to Deprecate SF Metadata

- Deprecated classes should be annotated with `@IsTest` at the class level so the class won't require test coverage.

- Deprecated triggers should be marked as `Inactive` so they don't run and won't need code coverage.

- It's fine to keep code in deprecated methods but please comment it out.

- If a field or object is no longer used, you should change the label to start with `Z_Deprecated` and update the description to say that it is no longer used by the package. All code references to deprecated objects and fields should be removed as soon as the field is deprecated.

- VisualForce pages that need to be deprecated should have all of their logic and code references removed. Deleting VisualForce pages from a managed package can cause package upgrade issues for customers and should be avoided at all cost.

## Additional Reading and Inspiration for UST Package Development Standards
- https://developer.salesforce.com/blogs/2022/01/drive-consistency-and-grow-developer-skills-with-a-developer-best-practices-checklist
- https://architect.salesforce.com/deliver/release-management-templates/development-standards/
- https://architect.salesforce.com/design/decision-guides/migrate-change
- https://developer.salesforce.com/docs/atlas.en-us.secure_coding_guide.meta/secure_coding_guide/secure_coding_guidelines.htm
- https://github.com/Coding-With-The-Force/SalesforceBestPractices/wiki/SF-Best-Practices-Documentation
