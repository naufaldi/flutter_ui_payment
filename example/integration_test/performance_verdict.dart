/// PRD §14 budget for the checkout and status workloads on a 60 Hz target.
const performanceWindow = Duration(seconds: 30);
const frameBudgetMs = 16.7;

const _workloads = ['checkout', 'status'];

/// Classifies the same summary that the driver writes to disk. Diagnostic
/// workloads are deliberately excluded from the budget.
Map<String, Object> performanceVerdict(Map<String, Object?> summary) {
  final refreshHz = summary['refresh_hz'];
  final environmentIssue = switch (summary['build_mode']) {
    'profile'
        when refreshHz is num &&
            refreshHz.isFinite &&
            (refreshHz - 60).abs() <= 0.1 =>
      null, // Includes nominal 60 Hz targets reporting 59.94 Hz.
    'profile' => 'A 60 Hz refresh rate is required.',
    _ => 'A profile-mode run is required.',
  };
  final workloads = {
    for (final name in _workloads)
      name: _workloadVerdict(summary[name], environmentIssue),
  };
  final states = workloads.values.map((workload) => workload['verdict']);
  return {
    'verdict': states.contains('inconclusive')
        ? 'inconclusive'
        : states.contains('fail')
        ? 'fail'
        : 'pass',
    'threshold_ms': frameBudgetMs,
    'workloads': workloads,
  };
}

Map<String, Object> _workloadVerdict(
  Object? evidence,
  String? environmentIssue,
) {
  if (environmentIssue != null) return _inconclusive(environmentIssue);
  if (evidence is! Map) return _inconclusive('Workload evidence is missing.');

  final frames = evidence['frames'];
  if (frames is! int || frames < 2) {
    return _inconclusive('No repeated frame samples were recorded.');
  }
  for (final phase in ['warm_up', 'measured']) {
    final elapsed = evidence['${phase}_elapsed_ms'];
    final iterations = evidence['${phase}_iterations'];
    if (elapsed is! int ||
        elapsed < performanceWindow.inMilliseconds ||
        iterations is! int ||
        iterations < 2) {
      return _inconclusive('The $phase window lacks 30 s of repeated work.');
    }
  }

  final overBudget = <String>[];
  for (final metric in ['build_p95_ms', 'raster_p95_ms']) {
    final value = evidence[metric];
    if (value is! num || !value.isFinite || value < 0) {
      return _inconclusive('A valid $metric is required.');
    }
    if (value >= frameBudgetMs) overBudget.add(metric);
  }
  return {
    'verdict': overBudget.isEmpty ? 'pass' : 'fail',
    'over_budget': overBudget,
  };
}

Map<String, Object> _inconclusive(String reason) => {
  'verdict': 'inconclusive',
  'reason': reason,
};
