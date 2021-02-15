Application.ensure_all_started(:telemetry)
Finch.start_link(name: Telegramex.HTTPClient)
ExUnit.start()
