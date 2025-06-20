import Config
config :notifications, Oban, testing: :manual

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :notifications, Notifications.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "postgres_notifications",
  database: "notifications_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :notifications, NotificationsWeb.Endpoint,
  http: [ip: {0, 0, 0, 0}, port: 4002],
  secret_key_base: "+t3y23VqHwftg49T+aZdEh2s/USz1A6WyMcv24yTvwPexF8TB5yBe6Mvk18VaSdm",
  server: false

# In test we don't send emails
config :notifications, Notifications.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :info

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true

config :notifications, Oban,
  repo: Notifications.Repo,
  testing: :inline

config :notifications, :endpoint_message, Notifications.Worker.EndpointMessageMock

config :tesla, adapter: Tesla.Mock
