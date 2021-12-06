#include <iostream>

class clock_gen {
private:
  uint64_t _increment;
  uint64_t _last_posedge;
  uint64_t _now;
  uint64_t _ticks;

public:
  clock_gen(uint64_t increment_ps) : clock_gen(increment_ps, 2 * increment_ps - 50) {}

  clock_gen(uint64_t increment_ps, uint64_t init_phase) {
    _increment = increment_ps;
    _last_posedge = 0;
    _now = init_phase;
    _ticks = 0;
  }

  uint64_t time_to_edge() {
    if (_last_posedge + _increment > _now)
      return _last_posedge + _increment - _now;
    else
      return _last_posedge + 2 * _increment - _now;
  }

  int advance(uint64_t delta_ps) {
    _now += delta_ps;

    if (_now >= _last_posedge + 2 * _increment) {
      _last_posedge += 2 * _increment;
      _ticks++;
      return 1;
    } else if (_now >= _last_posedge + _increment) {
      return 0;
    } else {
      return 1;
    }
  }

  bool rising_edge() {
    if (_now == _last_posedge)
      return true;
    return false;
  }

  bool falling_edge() {
    if (_now == _last_posedge + _increment)
      return true;
    return false;
  }
};
