class Topic < Project
  default_scope { unscoped.where(ownership_type: :lecturer) }
end
