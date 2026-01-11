# Rails Aliases

Ruby on Rails development shortcuts defined in `zsh/rails`.

## Bundler

| Alias | Command | Description |
|-------|---------|-------------|
| `be` | `bundle exec` | Run command with bundle |
| `bi` | `bundle install` | Install gems |
| `bu` | `bundle update` | Update gems |

## Rails Commands

| Alias | Command | Description |
|-------|---------|-------------|
| `rc` | `bin/rails console` | Rails console |
| `rs` | `bin/rails server` | Start Rails server |
| `rg` | `bin/rails generate` | Rails generator |
| `routes` | `bin/rails routes \| fzf -e` | Search routes with fzf |

### Routes with Fuzzy Search

The `routes` alias pipes output to fzf for interactive searching:

```bash
routes
# Type to filter, e.g., "users" or "POST"
```

## Database

| Alias | Command | Description |
|-------|---------|-------------|
| `migrate` | `bin/rails db:migrate` | Run migrations |
| `rollback` | `bin/rails db:rollback` | Rollback last migration |
| `dbseed` | `bin/rails db:seed` | Seed database |
| `dbreset` | `db:drop db:create db:migrate db:seed` | Full database reset |

### Database Reset

```bash
dbreset
# Drops, creates, migrates, and seeds in one command
```

## Testing - RSpec

| Alias | Command | Description |
|-------|---------|-------------|
| `rspec` | `bundle exec rspec` | Run RSpec |
| `sp` | `bundle exec rspec` | Short RSpec alias |
| `spf` | `bundle exec rspec --fail-fast` | Stop on first failure |

### Examples

```bash
sp                    # Run all specs
sp spec/models/       # Run model specs
spf spec/features/    # Run features, stop on failure
```

## Testing - Minitest

| Alias | Command | Description |
|-------|---------|-------------|
| `mt` | `bin/rails test` | Run tests |
| `mta` | `bin/rails test:all` | Run all tests |
| `mts` | `bin/rails test:system` | Run system tests |
| `mtf` | `bin/rails test --fail-fast` | Stop on first failure |

## Rake

| Alias | Command | Description |
|-------|---------|-------------|
| `rake` | `noglob bundle exec rake` | Rake without glob expansion |

The `noglob` prevents zsh from expanding `rake task[arg]` syntax:

```bash
rake "db:migrate[VERSION=123]"  # Works correctly
```

## Logs

| Alias | Command | Description |
|-------|---------|-------------|
| `devlog` | `tail -f log/development.log` | Follow dev log |
| `testlog` | `tail -f log/test.log` | Follow test log |
| `prodlog` | `tail -f log/production.log` | Follow prod log |

## Generators

| Alias | Command | Description |
|-------|---------|-------------|
| `scaffold` | `bin/rails generate scaffold` | Generate scaffold |
| `model` | `bin/rails generate model` | Generate model |
| `controller` | `bin/rails generate controller` | Generate controller |
| `migration` | `bin/rails generate migration` | Generate migration |

### Examples

```bash
model User name:string email:string
controller Users index show
migration AddAgeToUsers age:integer
scaffold Post title:string body:text user:references
```

## Common Workflows

### New Feature

```bash
# Create migration
migration AddStatusToOrders status:integer:index

# Run migration
migrate

# Open console to test
rc
```

### Fix Failing Tests

```bash
# Run with fail-fast
spf
# or
mtf

# Check logs
testlog
```

### Database Issues

```bash
# Full reset
dbreset

# Or step by step
rollback
migrate
dbseed
```

## Adding Custom Rails Aliases

Add to `~/.local/dotfiles/rails.local`:

```bash
# Project-specific aliases
alias myapp='cd ~/projects/myapp && rs'
alias myapp-console='cd ~/projects/myapp && rc'

# Sidekiq
alias sidekiq='bundle exec sidekiq'

# Debugging
alias debug='RAILS_LOG_LEVEL=debug rs'
```
