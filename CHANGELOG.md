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

[@BillFront]: https://github.com/BillFront
[@aishek]: https://github.com/aishek
[@VindictivePotato]: https://github.com/VindictivePotato
