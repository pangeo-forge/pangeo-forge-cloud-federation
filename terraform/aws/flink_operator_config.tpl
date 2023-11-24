kubernetes.operator.metrics.reporter.prom.factory.class: org.apache.flink.metrics.prometheus.PrometheusReporterFactory
kubernetes.operator.metrics.reporter.prom.factory.port: 9999
kubernetes.jobmanager.annotations:
  prometheus.io/scrape: true
  prometheus.io/port: 9999
jobmanager.archive.fs.dir: /opt/history/jobs
historyserver.archive.fs.dir: /opt/history/jobs