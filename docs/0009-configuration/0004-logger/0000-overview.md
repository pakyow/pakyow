---
title: Logger
---

Pakyow provides the following **environment** config options for the logger:

* <a href="#logger.level" name="logger.level">`logger.level`</a>: What level of logs to capture from.
<span class="default">Default: `:debug`; `:info` in *production*</span>

* <a href="#logger.formatter" name="logger.formatter">`logger.formatter`</a>: The formatter to use when writing logs.
<span class="default">Default: `Pakyow::Logger::DevFormatter`; `Pakyow::Logger::LogfmtFormatter` in *production*</span>

* <a href="#logger.destinations" name="logger.destinations">`logger.destinations`</a>: Array of `IO` objects or paths that log output should be written to.
<span class="default">Default: `[$stdout]`; `["/dev/null"]` if the logger is disabled</span>

* <a href="#logger.enabled" name="logger.enabled">`logger.enabled`</a>: Whether or not logging should occur at all. It's safe to set this to `false` without removing log statements from your code.
<span class="default">Default: `true` in *development*; `false` in *test*</span>
