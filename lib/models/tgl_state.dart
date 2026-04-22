enum TGLState {
  peaceful,
  someday,
  reality,
  noEscape,
  war,
}

class TGLThresholds {
  static const double peaceful = 0.4;
  static const double someday  = 1.5;
  static const double reality  = 6.0;
  static const double noEscape = 20.0;
}


TGLState tglToState(double tgl) {
  if (tgl < TGLThresholds.peaceful) return TGLState.peaceful;
  if (tgl < TGLThresholds.someday)  return TGLState.someday;
  if (tgl < TGLThresholds.reality)  return TGLState.reality;
  if (tgl < TGLThresholds.noEscape) return TGLState.noEscape;
  return TGLState.war;
}
