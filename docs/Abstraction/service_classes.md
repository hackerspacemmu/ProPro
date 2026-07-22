# Service classes

Everything that resides in `app/services`.

Service classes represent operations that coordinate changes between models (such as entities and value objects). Changes impact the state of the application (.new!, .save!, .update!).

1. When an object makes no changes to the state of the application, then it's not a service. It may be a query object or value object.
2. When there is no operation, there is no need to execute a service. The class would probably be better designed as a plain query object or value object.

When implementing a service class, follow these patterns:

## 1. Initializer arguments

1. The service class initializer should contain, in its arguments:
   1. A model instance that is being acted upon. This should be the first positional argument of the initializer. The argument name is left to the developer's discretion, such as `course`, `enrolment`, `project`.
   2. When the service represents an action initiated by a user or executed in the context of a user, the initializer must have a `current_user:` keyword argument. Services with `current_user:` run high-level business logic and must validate that the user is authorized to perform the operation.
   3. When the service does not have a user context and isn't directly initiated by a user (a background job, a side-effect of another operation), the `current_user:` argument is not needed.
   4. For all additional data required by a service, explicit keyword arguments are recommended. Only split into `params:`/`options:` hashes once a service's argument list gets long (roughly 4–5+ keyword arguments, or you're passing configuration that isn't a model attribute) — don't do this preemptively for a two- or three-argument service.

```ruby
# course: A model instance that is being acted upon.
# offsets: New per-lecturer capacity offsets to apply.
# excluded_ids: Enrolment IDs to exclude from auto-calculated capacity.
def initialize(course, offsets:, excluded_ids:)
  @course = course
  @offsets = offsets
  @excluded_ids = excluded_ids
end
```

```ruby
# issue: A model instance that is being acted upon.
# current_user: Current user. Required because this action is user-initiated
#   and must be authorization-checked.
# params: Model properties that will be assigned directly.
# options: Extra configuration for this service, not model properties.
def initialize(issue, current_user:, params: {}, options: {})
  @issue = issue
  @current_user = current_user
  @params = params
  @options = options
end
```

## 2. A single `#execute` method

The service class should implement a single public instance method, `#execute`, which invokes the service's behavior.

- `#execute` takes no arguments. All required data is passed in through the initializer.
- This matters more for a small, high-turnover team than it does for a large one: if every service is callable the exact same way, a contributor who has never seen the codebase before can guess how to call any service after seeing one example.

```ruby
# good
SupervisorCapacityUpdater.new(course, offsets: offsets, excluded_ids: excluded_ids).execute

# avoid — a generic `call` obscures what the service actually does
SupervisorCapacityUpdater.new(course, offsets: offsets, excluded_ids: excluded_ids).call
```

## 3. Return a rich result object, not a boolean

If a return value is needed, `#execute` should return its result via a `Result` object — never a bare `true`/`false`, and never an ActiveRecord instance on its own.

- A `Result` object can carry a success/failure state, an error list, and whatever data the caller actually needs — named and typed, not a generic hash the caller has to know the shape of.
- Every `Result` class should implement `success?` and `error?`, even though the rest of its shape is bespoke per service. This gives every caller a common way to check outcome without needing to know each service's specific accessors.

```ruby
class SupervisorCapacityUpdater
  class Result
    include ServiceResult # provides success?/error? from `errors.empty?`

    attr_reader :course, :errors

    def initialize(updated:, course:, errors: [])
      @updated = updated
      @course = course
      @errors = errors
    end

    def updated? = @updated
  end
end
```

```ruby
# ServiceResult — shared module, mixed into every service's Result class
module ServiceResult
  def success? = errors.empty?
  def error? = !success?
end
```

## 4. Patterns to avoid

1. **Creating class methods closes doors.** Prefer instance methods so a service can be composed, tested, and extended without `self.`-method gymnastics.
2. **Using a generic method name like `call` obscures behavior.** `execute` is the one exception to this — it's our team's single, deliberate convention specifically because it's the *only* public method a service ever exposes, so its genericness is the point. A class named `SupervisorCapacityUpdater` with an `execute` method still tells you exactly what happens when you call it; a class with an ambiguous name and a `call` method does not.
3. **Passing services into services via dependency injection obscures behavior.** If a service needs another service's output, instantiate it directly inside the method that needs it (as `SupervisorCapacityUpdater` does with `SupervisorCapacityCalculator`) rather than injecting it through the constructor. This keeps the dependency visible at the point it's used, and avoids needing container/wiring knowledge to trace what a service actually depends on.

### References

[GitLab's service class conventions](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/development/reusing_abstractions.md)