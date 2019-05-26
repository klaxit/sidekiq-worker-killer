**version 0.4.0**
- Fix grace time not getting honored [#8] by [@VindictivePotato]
- Add gc option and support Float::INFINITY for grace_time option [#4] by [@aishek]

**version 0.3.0**
- Run a full GC and then check memory again before initiating a restart
- Don't wait for grace time if there's no work
