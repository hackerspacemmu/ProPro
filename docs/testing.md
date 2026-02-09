core user flows:
- Project create
- Project update
- ProjectInstance Change Status
- Student import
- ProjectTemplates

### System testing

-  Use :rack_test for non-JavaScript User Flows
-  Uses DOM to locate content and assert on regular expressions. 
-  data-testid `attribute` should only be added to elements that have core user flows
-  CONVENTION: the first time a test must be changed to accommodate DOM changes, stop using the DOM for that assertion and start using data-testid.


### Unit Testing

-  Factory Bot for creating instances of objects that tests random fake values for fields
-  Tests business logic methods and validations (e.g current_instance & set_ownership_type )
-  Unit Testing should only really be done on models (or controllers) that capture a lot of business logic


### Database Constraints

-  tests check contrainsts on columns (e.g Project.create!)
-  Use `update_column` to skip validations to test db itself
-  CONVENTION: create tests to trigger errors to make sure the db constraint is working
 

### Seeds 

-  Use Factory Bot, Faker to generate seed data




### References 

[Sustainable Dev with Rails](https://unidel.edu.ng/focelibrary/books/Sustainable%20Web%20Development%20with%20Ruby%20on%20Rails%20Practical%20Tips%20for%20Building%20Web%20Applications%20that%20Last%20by%20David%20Bryant%20Copeland%20(z-lib.org).pdf)

Unit Testing - 17.3 Writing a System Test

Factory Bot - 16.5.3 Ensure Anyone Can Create Valid Instances of the Model
using Factory Bot

Database Constraints - 14.5 Writing Tests for Database Constraints 

System Testing - 12.5.1 Use data-testid Attributes to Combat Brittle Tests