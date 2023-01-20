**version 1.1.0**
- Add on_shutdown hook [#23] by [@Nirei]

**version 1.0.1**
- Support for Sidekiq >= 6.5.0. [#21] by [@bf4]

**version 1.0.0**
- Bump Sidekiq version to use the `Sidekiq::Process` API. [#12] by [@iGEL] and [#14] by [@pyrsmk]

**version 0.5.0**
- Option to skip shutdown on specific conditions (for example, for a specific job type). [#9] by [@msxavi]
- Ensure ProcessSet is up-to-date before checking for process that will need grace time. [#10] by [@msxavi]

**version 0.4.0**
- Fix grace time not getting honored. [#8] by [@VindictivePotato]
- Add gc option and support Float::INFINITY for grace_time option. [#4] by [@aishek]

**version 0.3.0**
- Run a full GC and then check memory again before initiating a restart. [#2] by [@BillFront]
- Don't wait for grace time if there's no work. [#1] by [@BillFront]

<!-- REFERENCES -->

[#1]: https://github.com/klaxit/sidekiq-worker-killer/pull/1
[#2]: https://github.com/klaxit/sidekiq-worker-killer/pull/2
[#4]: https://github.com/klaxit/sidekiq-worker-killer/pull/4
[#8]: https://github.com/klaxit/sidekiq-worker-killer/pull/8
[#9]: https://github.com/klaxit/sidekiq-worker-killer/pull/9
[#10]: https://github.com/klaxit/sidekiq-worker-killer/pull/10
[#12]: https://github.com/klaxit/sidekiq-worker-killer/pull/12
[#14]: https://github.com/klaxit/sidekiq-worker-killer/pull/14
[#21]: https://github.com/klaxit/sidekiq-worker-killer/pull/21
[#23]: https://github.com/klaxit/sidekiq-worker-killer/pull/23

[@aishek]: https://github.com/aishek
[@BillFront]: https://github.com/BillFront
[@iGEL]: https://github.com/iGEL
[@msxavi]: https://github.com/msxavi
[@pyrsmk]: https://github.com/pyrsmk
[@VindictivePotato]: https://github.com/VindictivePotato
[@bf4]: https://github.com/bf4
[@Nirei]: https://github.com/Nirei