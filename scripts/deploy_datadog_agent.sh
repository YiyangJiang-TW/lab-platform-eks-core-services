#!/usr/bin/env bash
set -e

export CLUSTER=$1
export DATADOG_CLUSTER_AGENT_VERSION=$(cat $CLUSTER.auto.tfvars.json | jq -r .datadog_cluster_agent_version)
export DATADOG_AGENT_VERSION=$(cat $CLUSTER.auto.tfvars.json | jq -r .datadog_agent_version)
export DATADOG_API_KEY=$(cat $CLUSTER.auto.tfvars.json | jq -r .datadog_api_key)
export DATADOG_APP_KEY=$(cat $CLUSTER.auto.tfvars.json | jq -r .datadog_app_key)

echo "DEBUG:"
echo "CLUSTER $CLUSTER"
echo "DATADOG_CLUSTER_AGENT_VERSION $DATADOG_CLUSTER_AGENT_VERSION"
echo "DATADOG_AGENT_VERSION $DATADOG_AGENT_VERSION"

cat <<EOF > datadog/values.yaml
# targetSystem -- Target OS for this deployment (possible values: linux, windows)
targetSystem: "linux"

registry: public.ecr.aws/datadog

datadog:
  # datadog.apiKey -- Your Datadog API key
  # ref: https://app.datadoghq.com/account/settings#agent/kubernetes
  apiKey: $DATADOG_API_KEY
  appKey: $DATADOG_APP_KEY

  ## Configure the secret backend feature https://docs.datadoghq.com/agent/guide/secrets-management
  ## Examples: https://docs.datadoghq.com/agent/guide/secrets-management/#setup-examples-1
  secretBackend:
    # datadog.secretBackend.command -- Configure the secret backend command, path to the secret backend binary.
    ## Note: If the command value is "/readsecret_multiple_providers.sh" the agents will have permissions to get secret objects.
    ## Read more about "/readsecret_multiple_providers.sh": https://docs.datadoghq.com/agent/guide/secrets-management/#script-for-reading-from-multiple-secret-providers-readsecret_multiple_providerssh
    command:  # "/readsecret.sh" or "/readsecret_multiple_providers.sh" or any custom binary path

    # datadog.secretBackend.arguments -- Configure the secret backend command arguments (space-separated strings).
    arguments:  # "/etc/secret-volume" or any other custom arguments

    # datadog.secretBackend.timeout -- Configure the secret backend command timeout in seconds.
    timeout:  # 30

  # datadog.securityContext -- Allows you to overwrite the default PodSecurityContext on the Daemonset or Deployment
  securityContext: {}
  #  seLinuxOptions:
  #    user: "system_u"
  #    role: "system_r"
  #    type: "spc_t"
  #    level: "s0"

  hostVolumeMountPropagation: None

  # datadog.clusterName -- Set a unique cluster name to allow scoping hosts and Cluster Checks easily
  ## The name must be unique and must be dot-separated tokens with the following restrictions:
  ## * Lowercase letters, numbers, and hyphens only.
  ## * Must start with a letter.
  ## * Must end with a number or a letter.
  ## * Overall length should not be higher than 80 characters.
  ## Compared to the rules of GKE, dots are allowed whereas they are not allowed on GKE:
  ## https://cloud.google.com/kubernetes-engine/docs/reference/rest/v1beta1/projects.locations.clusters#Cluster.FIELDS.name
  clusterName: $CLUSTER

  # datadog.site -- The site of the Datadog intake to send Agent data to
  ## Set to 'datadoghq.eu' to send data to the EU site.
  site:  # datadoghq.com

  # datadog.dd_url -- The host of the Datadog intake server to send Agent data to, only set this option if you need the Agent to send data to a custom URL
  ## Overrides the site setting defined in "site".
  dd_url:  # https://app.datadoghq.com

  # datadog.logLevel -- Set logging verbosity, valid log levels are: trace, debug, info, warn, error, critical, off
  logLevel: INFO

  # datadog.kubeStateMetricsEnabled -- If true, deploys the kube-state-metrics deployment
  ## ref: https://github.com/kubernetes/kube-state-metrics/tree/kube-state-metrics-helm-chart-2.13.2/charts/kube-state-metrics
  kubeStateMetricsEnabled: false

  kubeStateMetricsNetworkPolicy:
    # datadog.kubeStateMetricsNetworkPolicy.create -- If true, create a NetworkPolicy for kube state metrics
    create: false

  kubeStateMetricsCore:
    # datadog.kubeStateMetricsCore.enabled -- Enable the kubernetes_state_core check in the Cluster Agent (Requires Cluster Agent 1.12.0+)
    ## ref: https://docs.datadoghq.com/integrations/kubernetes_state_core
    enabled: false

    # datadog.kubeStateMetricsCore.ignoreLegacyKSMCheck -- Disable the auto-configuration of legacy kubernetes_state check (taken into account only when datadog.kubeStateMetricsCore.enabled is true)
    ## Disabling this field is not recommended as it results in enabling both checks, it can be useful though during the migration phase.
    ## Migration guide: https://docs.datadoghq.com/integrations/kubernetes_state_core/?tab=helm#migration-from-kubernetes_state-to-kubernetes_state_core
    ignoreLegacyKSMCheck: true

    # datadog.kubeStateMetricsCore.collectSecretMetrics -- Enable watching secret objects and collecting their corresponding metrics kubernetes_state.secret.*
    ## Configuring this field will change the default kubernetes_state_core check configuration and the RBACs granted to Datadog Cluster Agent to run the kubernetes_state_core check.
    collectSecretMetrics: false

    # datadog.kubeStateMetricsCore.useClusterCheckRunners -- For large clusters where the Kubernetes State Metrics Check Core needs to be distributed on dedicated workers.
    ## Configuring this field will create a separate deployment which will run Cluster Checks, including Kubernetes State Metrics Core.
    ## ref: https://docs.datadoghq.com/agent/cluster_agent/clusterchecksrunner?tab=helm
    useClusterCheckRunners: false

    # datadog.kubeStateMetricsCore.labelsAsTags -- Extra labels to collect from resources and to turn into datadog tag.
    ## It has the following structure:
    ## labelsAsTags:
    ##   <resource1>:        # can be pod, deployment, node, etc.
    ##     <label1>: <tag1>  # where <label1> is the kubernetes label and <tag1> is the datadog tag
    ##     <label2>: <tag2>
    ##   <resource2>:
    ##     <label3>: <tag3>
    ##
    ## Warning: the label must match the transformation done by kube-state-metrics,
    ## for example tags.datadoghq.com/version becomes label_tags_datadoghq_com_version.
    labelsAsTags: {}
    #  pod:
    #    app: app
    #  node:
    #    zone: zone
    #    team: team

  ## Manage Cluster checks feature
  ## ref: https://docs.datadoghq.com/agent/autodiscovery/clusterchecks/
  ## Autodiscovery via Kube Service annotations is automatically enabled
  clusterChecks:
    # datadog.clusterChecks.enabled -- Enable the Cluster Checks feature on both the cluster-agents and the daemonset
    enabled: true

  # datadog.nodeLabelsAsTags -- Provide a mapping of Kubernetes Node Labels to Datadog Tags
  nodeLabelsAsTags: {}
  #   beta.kubernetes.io/instance-type: aws-instance-type
  #   kubernetes.io/role: kube_role
  #   <KUBERNETES_NODE_LABEL>: <DATADOG_TAG_KEY>

  # datadog.podLabelsAsTags -- Provide a mapping of Kubernetes Labels to Datadog Tags
  podLabelsAsTags: {}
  #   app: kube_app
  #   release: helm_release
  #   <KUBERNETES_LABEL>: <DATADOG_TAG_KEY>

  # datadog.podAnnotationsAsTags -- Provide a mapping of Kubernetes Annotations to Datadog Tags
  podAnnotationsAsTags: {}
  #   iam.amazonaws.com/role: kube_iamrole
  #   <KUBERNETES_ANNOTATIONS>: <DATADOG_TAG_KEY>

  # datadog.namespaceLabelsAsTags -- Provide a mapping of Kubernetes Namespace Labels to Datadog Tags
  namespaceLabelsAsTags: {}
  #   env: environment
  #   <KUBERNETES_NAMESPACE_LABEL>: <DATADOG_TAG_KEY>


  # datadog.tags -- List of static tags to attach to every metric, event and service check collected by this Agent.
  ## Learn more about tagging: https://docs.datadoghq.com/tagging/
  tags:
    - "cluster:$CLUSTER"

  # datadog.checksCardinality -- Sets the tag cardinality for the checks run by the Agent.
  ## https://docs.datadoghq.com/getting_started/tagging/assigning_tags/?tab=containerizedenvironments#environment-variables
  checksCardinality:  # low, orchestrator or high (not set by default to avoid overriding existing DD_CHECKS_TAG_CARDINALITY configurations, the default value in the Agent is low)

  # kubelet configuration
  kubelet:
    # datadog.kubelet.host -- Override kubelet IP
    host:
      valueFrom:
        fieldRef:
          fieldPath: status.hostIP
    # datadog.kubelet.tlsVerify -- Toggle kubelet TLS verification
    # @default -- true
    tlsVerify:  # false
    # datadog.kubelet.hostCAPath -- Path (on host) where the Kubelet CA certificate is stored
    # @default -- None (no mount from host)
    hostCAPath:
    # datadog.kubelet.agentCAPath -- Path (inside Agent containers) where the Kubelet CA certificate is stored
    # @default -- /var/run/host-kubelet-ca.crt if hostCAPath else /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
    agentCAPath:

  # datadog.expvarPort -- Specify the port to expose pprof and expvar to not interfer with the agentmetrics port from the cluster-agent, which defaults to 5000
  expvarPort: 6000

  ## dogstatsd configuration
  ## ref: https://docs.datadoghq.com/agent/kubernetes/dogstatsd/
  ## To emit custom metrics from your Kubernetes application, use DogStatsD.
  dogstatsd:
    # datadog.dogstatsd.port -- Override the Agent DogStatsD port
    ## Note: Make sure your client is sending to the same UDP port.
    port: 8125

    # datadog.dogstatsd.originDetection -- Enable origin detection for container tagging
    ## https://docs.datadoghq.com/developers/dogstatsd/unix_socket/#using-origin-detection-for-container-tagging
    originDetection: false

    # datadog.dogstatsd.tags -- List of static tags to attach to every custom metric, event and service check collected by Dogstatsd.
    ## Learn more about tagging: https://docs.datadoghq.com/tagging/
    tags:
      - "cluster:$CLUSTER"

    # datadog.dogstatsd.tagCardinality -- Sets the tag cardinality relative to the origin detection
    ## https://docs.datadoghq.com/developers/dogstatsd/unix_socket/#using-origin-detection-for-container-tagging
    tagCardinality: low

    # datadog.dogstatsd.useSocketVolume -- Enable dogstatsd over Unix Domain Socket with an HostVolume
    ## ref: https://docs.datadoghq.com/developers/dogstatsd/unix_socket/
    useSocketVolume: true

    # datadog.dogstatsd.socketPath -- Path to the DogStatsD socket
    socketPath: /var/run/datadog/dsd.socket

    # datadog.dogstatsd.hostSocketPath -- Host path to the DogStatsD socket
    hostSocketPath: /var/run/datadog/

    # datadog.dogstatsd.useHostPort -- Sets the hostPort to the same value of the container port
    ## Needs to be used for sending custom metrics.
    ## The ports need to be available on all hosts.
    ##
    ## WARNING: Make sure that hosts using this are properly firewalled otherwise
    ## metrics and traces are accepted from any host able to connect to this host.
    useHostPort: false

    # datadog.dogstatsd.useHostPID -- Run the agent in the host's PID namespace
    ## This is required for Dogstatsd origin detection to work.
    ## See https://docs.datadoghq.com/developers/dogstatsd/unix_socket/
    useHostPID: false

    # datadog.dogstatsd.nonLocalTraffic -- Enable this to make each node accept non-local statsd traffic (from outside of the pod)
    ## ref: https://github.com/DataDog/docker-dd-agent#environment-variables
    nonLocalTraffic: true

  # datadog.collectEvents -- Enables this to start event collection from the kubernetes API
  ## ref: https://docs.datadoghq.com/agent/kubernetes/#event-collection
  collectEvents: true

  # datadog.leaderElection -- Enables leader election mechanism for event collection
  leaderElection: true

  # datadog.leaderLeaseDuration -- Set the lease time for leader election in second
  leaderLeaseDuration:  # 60

  ## Enable logs agent and provide custom configs
  logs:
    # datadog.logs.enabled -- Enables this to activate Datadog Agent log collection
    ## ref: https://docs.datadoghq.com/agent/basic_agent_usage/kubernetes/#log-collection-setup
    enabled: true

    # datadog.logs.containerCollectAll -- Enable this to allow log collection for all containers
    ## ref: https://docs.datadoghq.com/agent/basic_agent_usage/kubernetes/#log-collection-setup
    containerCollectAll: true

    # datadog.logs.containerCollectUsingFiles -- Collect logs from files in /var/log/pods instead of using container runtime API
    ## It's usually the most efficient way of collecting logs.
    ## ref: https://docs.datadoghq.com/agent/basic_agent_usage/kubernetes/#log-collection-setup
    containerCollectUsingFiles: true

    # datadog.logs.autoMultiLineDetection -- Allows the Agent to detect common multi-line patterns automatically.
    ## ref: https://docs.datadoghq.com/agent/logs/advanced_log_collection/?tab=configurationfile#automatic-multi-line-aggregation
    autoMultiLineDetection: true

  ## Enable apm agent and provide custom configs
  apm:
    # datadog.apm.socketEnabled -- Enable APM over Socket (Unix Socket or windows named pipe)
    ## ref: https://docs.datadoghq.com/agent/kubernetes/apm/
    socketEnabled: false

    # datadog.apm.portEnabled -- Enable APM over TCP communication (port 8126 by default)
    ## ref: https://docs.datadoghq.com/agent/kubernetes/apm/
    portEnabled: false

    # datadog.apm.enabled -- Enable this to enable APM and tracing, on port 8126
    # DEPRECATED. Use datadog.apm.portEnabled instead
    ## ref: https://github.com/DataDog/docker-dd-agent#tracing-from-the-host
    enabled: false

    # datadog.apm.port -- Override the trace Agent port
    ## Note: Make sure your client is sending to the same UDP port.
    port: 8126

    # datadog.apm.useSocketVolume -- Enable APM over Unix Domain Socket
    # DEPRECATED. Use datadog.apm.socketEnabled instead
    ## ref: https://docs.datadoghq.com/agent/kubernetes/apm/
    useSocketVolume: false

    # datadog.apm.socketPath -- Path to the trace-agent socket
    socketPath: /var/run/datadog/apm.socket

    # datadog.apm.hostSocketPath -- Host path to the trace-agent socket
    hostSocketPath: /var/run/datadog/

  # datadog.envFrom -- Set environment variables for all Agents directly from configMaps and/or secrets
  ## envFrom to pass configmaps or secrets as environment
  envFrom: []
  #   - configMapRef:
  #       name: <CONFIGMAP_NAME>
  #   - secretRef:
  #       name: <SECRET_NAME>

  # datadog.env -- Set environment variables for all Agents
  ## The Datadog Agent supports many environment variables.
  ## ref: https://docs.datadoghq.com/agent/docker/?tab=standard#environment-variables
  env:
    - name: DD_COLLECT_KUBERNETES_EVENTS
      value: "true"
    - name: DD_AUTOCONFIG_INCLUDE_FEATURES
      value: "containerd"

  # datadog.confd -- Provide additional check configurations (static and Autodiscovery)
  ## Each key becomes a file in /conf.d
  ## ref: https://github.com/DataDog/datadog-agent/tree/main/Dockerfiles/agent#optional-volumes
  ## ref: https://docs.datadoghq.com/agent/autodiscovery/
  confd:
    istio.yaml: |-
      init_config:
        service: <SERVICE>

      instances:
        - use_openmetrics: true
          istiod_endpoint: http://istiod.istio-system:15014/metrics
          # istio_mesh_endpoint: http://istio-proxy.istio-system:15090/stats/prometheus
          # openmetrics_endpoint: localhost:15090/stats/prometheus
          exclude_labels:
            - source_version
            - destination_version
            - source_canonical_revision
            - destination_canonical_revision
            - source_principal
            - destination_principal
            - source_cluster
            - destination_cluster
            - source_canonical_service
            - destination_canonical_service
            - source_workload_namespace
            - destination_workload_namespace
            - request_protocol
            - connection_security_policy

      logs:
        "source": "istio"
        "service": "<SERVICE_NAME>"

  #   redisdb.yaml: |-
  #     init_config:
  #     instances:
  #       - host: "name"
  #         port: "6379"
  #   kubernetes_state.yaml: |-
  #     ad_identifiers:
  #       - kube-state-metrics
  #     init_config:
  #     instances:
  #       - kube_state_url: http://%%host%%:8080/metrics

  # datadog.checksd -- Provide additional custom checks as python code
  ## Each key becomes a file in /checks.d
  ## ref: https://github.com/DataDog/datadog-agent/tree/main/Dockerfiles/agent#optional-volumes
  checksd: {}
  #   service.py: |-

  # datadog.dockerSocketPath -- Path to the docker socket
  dockerSocketPath:  # /var/run/docker.sock

  # datadog.criSocketPath -- Path to the container runtime socket (if different from Docker) # /var/run/containerd/containerd.sock
  criSocketPath:  # /run/dockershim.sock bottlerock support

  ## Enable process agent and provide custom configs
  processAgent:
    # datadog.processAgent.enabled -- Set this to true to enable live process monitoring agent
    ## Note: /etc/passwd is automatically mounted to allow username resolution.
    ## ref: https://docs.datadoghq.com/graphing/infrastructure/process/#kubernetes-daemonset
    enabled: true

    # datadog.processAgent.processCollection -- Set this to true to enable process collection in process monitoring agent
    ## Requires processAgent.enabled to be set to true to have any effect
    processCollection: true

    # datadog.processAgent.stripProcessArguments -- Set this to scrub all arguments from collected processes
    ## Requires processAgent.enabled and processAgent.processCollection to be set to true to have any effect
    ## ref: https://docs.datadoghq.com/infrastructure/process/?tab=linuxwindows#process-arguments-scrubbing
    stripProcessArguments: true

    # datadog.processAgent.processDiscovery -- Enables or disables autodiscovery of integrations
    processDiscovery: false

  ## Enable systemProbe agent and provide custom configs
  systemProbe:

    # datadog.systemProbe.debugPort -- Specify the port to expose pprof and expvar for system-probe agent
    debugPort: 0

    enableConntrack: false

    seccomp: localhost/system-probe

    # datadog.systemProbe.seccompRoot -- Specify the seccomp profile root directory
    seccompRoot: /var/lib/kubelet/seccomp

    # datadog.systemProbe.bpfDebug -- Enable logging for kernel debug
    bpfDebug: false

    # datadog.systemProbe.apparmor -- Specify a apparmor profile for system-probe
    apparmor: unconfined

    # datadog.systemProbe.enableTCPQueueLength -- Enable the TCP queue length eBPF-based check
    enableTCPQueueLength: false

    # datadog.systemProbe.enableOOMKill -- Enable the OOM kill eBPF-based check
    enableOOMKill: false

    # datadog.systemProbe.enableRuntimeCompiler -- Enable the runtime compiler for eBPF probes
    enableRuntimeCompiler: false

    mountPackageManagementDirs: []

    osReleasePath:

    # datadog.systemProbe.runtimeCompilationAssetDir -- Specify a directory for runtime compilation assets to live in
    runtimeCompilationAssetDir: /var/tmp/datadog-agent/system-probe

    # datadog.systemProbe.collectDNSStats -- Enable DNS stat collection
    collectDNSStats: false

    # datadog.systemProbe.maxTrackedConnections -- the maximum number of tracked connections
    maxTrackedConnections: 131072

    # datadog.systemProbe.conntrackMaxStateSize -- the maximum size of the userspace conntrack cache
    conntrackMaxStateSize: 131072  # 2 * maxTrackedConnections by default, per  https://github.com/DataDog/datadog-agent/blob/d1c5de31e1bba72dfac459aed5ff9562c3fdcc20/pkg/process/config/config.go#L229

    # datadog.systemProbe.conntrackInitTimeout -- the time to wait for conntrack to initialize before failing
    conntrackInitTimeout: 10s

  orchestratorExplorer:
    # datadog.orchestratorExplorer.enabled -- Set this to false to disable the orchestrator explorer
    ## This requires processAgent.enabled and clusterAgent.enabled to be set to true
    ## ref: TODO - add doc link
    enabled: true

    # datadog.orchestratorExplorer.container_scrubbing -- Enable the scrubbing of containers in the kubernetes resource YAML for sensitive information
    ## The container scrubbing is taking significant resources during data collection.
    ## If you notice that the cluster-agent uses too much CPU in larger clusters
    ## turning this option off will improve the situation.
    container_scrubbing:
      enabled: true

  networkMonitoring:
    # datadog.networkMonitoring.enabled -- Enable network performance monitoring
    enabled: true

  ## Universal Service Monitoring is currently in private beta.
  ## See https://www.datadoghq.com/blog/universal-service-monitoring-datadog/ for more details and private beta signup.
  serviceMonitoring:
    # datadog.serviceMonitoring.enabled -- Enable Universal Service Monitoring
    enabled: false

  ## Enable security agent and provide custom configs
  securityAgent:
    compliance:
      # datadog.securityAgent.compliance.enabled -- Set to true to enable Cloud Security Posture Management (CSPM)
      enabled: false

      # datadog.securityAgent.compliance.configMap -- Contains CSPM compliance benchmarks that will be used
      configMap:

      # datadog.securityAgent.compliance.checkInterval -- Compliance check run interval
      checkInterval: 20m

    runtime:
      # datadog.securityAgent.runtime.enabled -- Set to true to enable Cloud Workload Security (CWS)
      enabled: false

      policies:
        # datadog.securityAgent.runtime.policies.configMap -- Contains CWS policies that will be used
        configMap:

      syscallMonitor:
        # datadog.securityAgent.runtime.syscallMonitor.enabled -- Set to true to enable the Syscall monitoring (recommended for troubleshooting only)
        enabled: false

  ## Manage NetworkPolicy
  networkPolicy:
    # datadog.networkPolicy.create -- If true, create NetworkPolicy for all the components
    create: false

    # datadog.networkPolicy.flavor -- Flavor of the network policy to use.
    # Can be:
    # * kubernetes for networking.k8s.io/v1/NetworkPolicy
    # * cilium     for cilium.io/v2/CiliumNetworkPolicy
    flavor: kubernetes

    cilium:
      # datadog.networkPolicy.cilium.dnsSelector -- Cilium selector of the DNS server entity
      # @default -- kube-dns in namespace kube-system
      dnsSelector:
        toEndpoints:
          - matchLabels:
              "k8s:io.kubernetes.pod.namespace": kube-system
              "k8s:k8s-app": kube-dns

  ## Configure prometheus scraping autodiscovery
  ## ref: https://docs.datadoghq.com/agent/kubernetes/prometheus/
  prometheusScrape:
    # datadog.prometheusScrape.enabled -- Enable autodiscovering pods and services exposing prometheus metrics.
    enabled: false
    # datadog.prometheusScrape.serviceEndpoints -- Enable generating dedicated checks for service endpoints.
    serviceEndpoints: false
    # datadog.prometheusScrape.additionalConfigs -- Allows adding advanced openmetrics check configurations with custom discovery rules. (Requires Agent version 7.27+)
    additionalConfigs: []
      # -
      #   autodiscovery:
      #     kubernetes_annotations:
      #       include:
      #         custom_include_label: 'true'
      #       exclude:
      #         custom_exclude_label: 'true'
      #     kubernetes_container_names:
      #     - my-app
      #   configurations:
      #   - send_distribution_buckets: true
      #     timeout: 5

  # datadog.ignoreAutoConfig -- List of integration to ignore auto_conf.yaml.
  ## ref: https://docs.datadoghq.com/agent/faq/auto_conf/
  ignoreAutoConfig: []
  #  - redisdb
  #  - kubernetes_state


  containerExclude:  # "image:datadog/agent"


  containerInclude:

  # datadog.containerExcludeLogs -- Exclude logs from the Agent Autodiscovery,
  # as a space-separated list
  containerExcludeLogs:

  # datadog.containerIncludeLogs -- Include logs in the Agent Autodiscovery, as
  # a space-separated list
  containerIncludeLogs:

  # datadog.containerExcludeMetrics -- Exclude metrics from the Agent
  # Autodiscovery, as a space-separated list
  containerExcludeMetrics:

  # datadog.containerIncludeMetrics -- Include metrics in the Agent
  # Autodiscovery, as a space-separated list
  containerIncludeMetrics:

  excludePauseContainer: true

clusterAgent:
  # clusterAgent.enabled -- Set this to false to disable Datadog Cluster Agent
  enabled: true

  ## Define the Datadog Cluster-Agent image to work with
  image:
    name: cluster-agent

    # clusterAgent.image.tag -- Cluster Agent image tag to use
    tag: $DATADOG_CLUSTER_AGENT_VERSION

    # clusterAgent.image.pullPolicy -- Cluster Agent image pullPolicy
    pullPolicy: IfNotPresent


  # clusterAgent.securityContext -- Allows you to overwrite the default PodSecurityContext on the cluster-agent pods.
  securityContext: {}

  containers:
    clusterAgent:
      # clusterAgent.containers.clusterAgent.securityContext -- Specify securityContext on the cluster-agent container.
      securityContext: {}

  # clusterAgent.command -- Command to run in the Cluster Agent container as entrypoint
  command: []

  # clusterAgent.token -- Cluster Agent token is a preshared key between node agents and cluster agent (autogenerated if empty, needs to be at least 32 characters a-zA-z)
  token: ""

  # clusterAgent.tokenExistingSecret -- Existing secret name to use for Cluster Agent token
  tokenExistingSecret: ""

  # clusterAgent.replicas -- Specify the of cluster agent replicas, if > 1 it allow the cluster agent to work in HA mode.
  replicas: 2



  ## Provide Cluster Agent Deployment pod(s) RBAC configuration
  rbac:
    # clusterAgent.rbac.create -- If true, create & use RBAC resources
    create: true

    # clusterAgent.rbac.serviceAccountName -- Specify a preexisting ServiceAccount to use if clusterAgent.rbac.create is false
    serviceAccountName: default

    # clusterAgent.rbac.serviceAccountAnnotations -- Annotations to add to the ServiceAccount if clusterAgent.rbac.create is true
    serviceAccountAnnotations: {}

  ## Provide Cluster Agent pod security configuration
  podSecurity:
    podSecurityPolicy:
      # clusterAgent.podSecurity.podSecurityPolicy.create -- If true, create a PodSecurityPolicy resource for Cluster Agent pods
      create: false
    securityContextConstraints:
      # clusterAgent.podSecurity.securityContextConstraints.create -- If true, create a SCC resource for Cluster Agent pods
      create: false


  # Enable the metricsProvider to be able to scale based on metrics in Datadog
  metricsProvider:
    # clusterAgent.metricsProvider.enabled -- Set this to true to enable Metrics Provider
    enabled: true
    wpaController: false


    useDatadogMetrics: true
    createReaderRbac: true

    # clusterAgent.metricsProvider.aggregator -- Define the aggregator the cluster agent will use to process the metrics. The options are (avg, min, max, sum)
    aggregator: avg

    ## Configuration for the service for the cluster-agent metrics server
    service:
      # clusterAgent.metricsProvider.service.type -- Set type of cluster-agent metrics server service
      type: ClusterIP

      # clusterAgent.metricsProvider.service.port -- Set port of cluster-agent metrics server service (Kubernetes >= 1.15)
      port: 8443

    endpoint:  # https://api.datadoghq.com

  # clusterAgent.env -- Set environment variables specific to Cluster Agent
  ## The Cluster-Agent supports many additional environment variables
  ## ref: https://docs.datadoghq.com/agent/cluster_agent/commands/#cluster-agent-options
  env:
    - name: DD_CLUSTER_CHECKS_ENABLED
      value: "true"
    - name: DD_CLUSTER_NAME
      value: $CLUSTER

  # clusterAgent.envFrom --  Set environment variables specific to Cluster Agent from configMaps and/or secrets
  ## The Cluster-Agent supports many additional environment variables
  ## ref: https://docs.datadoghq.com/agent/cluster_agent/commands/#cluster-agent-options
  envFrom: []
  #   - configMapRef:
  #       name: <CONFIGMAP_NAME>
  #   - secretRef:
  #       name: <SECRET_NAME>

  admissionController:
    # clusterAgent.admissionController.enabled -- Enable the admissionController to be able to inject APM/Dogstatsd config and standard tags (env, service, version) automatically into your pods
    enabled: false

    # clusterAgent.admissionController.mutateUnlabelled -- Enable injecting config without having the pod label 'admission.datadoghq.com/enabled="true"'
    mutateUnlabelled: false



  # clusterAgent.confd -- Provide additional cluster check configurations. Each key will become a file in /conf.d.
  ## ref: https://docs.datadoghq.com/agent/autodiscovery/
  confd: {}
  #   mysql.yaml: |-
  #     cluster_check: true
  #     instances:
  #       - host: <EXTERNAL_IP>
  #         port: 3306
  #         username: datadog
  #         password: <YOUR_CHOSEN_PASSWORD>

  # clusterAgent.advancedConfd -- Provide additional cluster check configurations. Each key is an integration containing several config files.
  ## ref: https://docs.datadoghq.com/agent/autodiscovery/
  advancedConfd: {}
  #  mysql.d:
  #    1.yaml: |-
  #      cluster_check: true
  #      instances:
  #        - host: <EXTERNAL_IP>
  #          port: 3306
  #          username: datadog
  #          password: <YOUR_CHOSEN_PASSWORD>
  #    2.yaml:  |-
  #      cluster_check: true
  #      instances:
  #        - host: <EXTERNAL_IP>
  #          port: 3306
  #          username: datadog
  #          password: <YOUR_CHOSEN_PASSWORD>

  # clusterAgent.resources -- Datadog cluster-agent resource requests and limits.
  resources: {}
  # requests:
  #   cpu: 200m
  #   memory: 256Mi
  # limits:
  #   cpu: 200m
  #   memory: 256Mi

  # clusterAgent.priorityClassName -- Name of the priorityClass to apply to the Cluster Agent
  priorityClassName:  # system-cluster-critical

  # clusterAgent.nodeSelector -- Allow the Cluster Agent Deployment to be scheduled on selected nodes
  ## Ref: https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#nodeselector
  ## Ref: https://kubernetes.io/docs/user-guide/node-selection/
  nodeSelector: {}



  # clusterAgent.tolerations -- Allow the Cluster Agent Deployment to schedule on tainted nodes ((requires Kubernetes >= 1.6))
  ## Ref: https://kubernetes.io/docs/concepts/configuration/taint-and-toleration/
  tolerations: []

  # clusterAgent.affinity -- Allow the Cluster Agent Deployment to schedule using affinity rules
  ## By default, Cluster Agent Deployment Pods are forced to run on different Nodes.
  ## Ref: https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#affinity-and-anti-affinity
  affinity: {}

  # clusterAgent.healthPort -- Port number to use in the Cluster Agent for the healthz endpoint
  healthPort: 5556

  # clusterAgent.livenessProbe -- Override default Cluster Agent liveness probe settings
  # @default -- Every 15s / 6 KO / 1 OK
  livenessProbe:
    initialDelaySeconds: 15
    periodSeconds: 15
    timeoutSeconds: 5
    successThreshold: 1
    failureThreshold: 6

  # clusterAgent.readinessProbe -- Override default Cluster Agent readiness probe settings
  # @default -- Every 15s / 6 KO / 1 OK
  readinessProbe:
    initialDelaySeconds: 15
    periodSeconds: 15
    timeoutSeconds: 5
    successThreshold: 1
    failureThreshold: 6

  # clusterAgent.strategy -- Allow the Cluster Agent deployment to perform a rolling update on helm update
  ## ref: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#strategy
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 2
      maxUnavailable: 1

  # clusterAgent.deploymentAnnotations -- Annotations to add to the cluster-agents's deployment
  deploymentAnnotations: {}
  #   key: "value"

  # clusterAgent.podAnnotations -- Annotations to add to the cluster-agents's pod(s)
  podAnnotations: {}
  #   key: "value"

  # clusterAgent.useHostNetwork -- Bind ports on the hostNetwork
  ## Useful for CNI networking where hostPort might
  ## not be supported. The ports need to be available on all hosts. It can be
  ## used for custom metrics instead of a service endpoint.
  ##
  ## WARNING: Make sure that hosts using this are properly firewalled otherwise
  ## metrics and traces are accepted from any host able to connect to this host.
  #
  useHostNetwork: false

  # clusterAgent.dnsConfig -- Specify dns configuration options for datadog cluster agent containers e.g ndots
  ## ref: https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/#pod-dns-config
  dnsConfig: {}
  #  options:
  #  - name: ndots
  #    value: "1"

  # clusterAgent.volumes -- Specify additional volumes to mount in the cluster-agent container
  volumes: []
  #   - hostPath:
  #       path: <HOST_PATH>
  #     name: <VOLUME_NAME>

  # clusterAgent.volumeMounts -- Specify additional volumes to mount in the cluster-agent container
  volumeMounts: []
  #   - name: <VOLUME_NAME>
  #     mountPath: <CONTAINER_PATH>
  #     readOnly: true

  # clusterAgent.datadog_cluster_yaml -- Specify custom contents for the datadog cluster agent config (datadog-cluster.yaml)
  datadog_cluster_yaml: {}

  # clusterAgent.createPodDisruptionBudget -- Create pod disruption budget for Cluster Agent deployments
  createPodDisruptionBudget: true

  networkPolicy:
    # clusterAgent.networkPolicy.create -- If true, create a NetworkPolicy for the cluster agent.
    # DEPRECATED. Use datadog.networkPolicy.create instead
    create: false

  # clusterAgent.additionalLabels -- Adds labels to the Cluster Agent deployment and pods
  additionalLabels: {}
    # key: "value"


## This section lets you configure the agents deployed by this chart to connect to a Cluster Agent
## deployed independently
existingClusterAgent:
  # existingClusterAgent.join -- set this to true if you want the agents deployed by this chart to
  # connect to a Cluster Agent deployed independently
  join: false

  # existingClusterAgent.tokenSecretName -- Existing secret name to use for external Cluster Agent token
  tokenSecretName:  # <EXISTING_DCA_SECRET_NAME>

  # existingClusterAgent.serviceName -- Existing service name to use for reaching the external Cluster Agent
  serviceName:  # <EXISTING_DCA_SERVICE_NAME>

  # existingClusterAgent.clusterchecksEnabled -- set this to false if you don’t want the agents to run the cluster checks of the joined external cluster agent
  clusterchecksEnabled: true



agents:

  enabled: true

  ## Define the Datadog image to work with
  image:

    ## use "dogstatsd" for Standalone Datadog Agent DogStatsD 7
    name: agent

    # agents.image.tag -- Define the Agent version to use
    tag: $DATADOG_AGENT_VERSION

    # agents.image.tagSuffix -- Suffix to append to Agent tag
    ## Ex:
    ##  jmx        to enable jmx fetch collection
    ##  servercore to get Windows images based on servercore
    tagSuffix: ""

    # agents.image.repository -- Override default registry + image.name for Agent
    repository:


    doNotCheckTag:  # false

    # agents.image.pullPolicy -- Datadog Agent image pull policy
    pullPolicy: IfNotPresent

    pullSecrets: []
    #   - name: "<REG_SECRET>"

  ## Provide Daemonset RBAC configuration
  rbac:
    # agents.rbac.create -- If true, create & use RBAC resources
    create: true

    # agents.rbac.serviceAccountName -- Specify a preexisting ServiceAccount to use if agents.rbac.create is false
    serviceAccountName: default

    # agents.rbac.serviceAccountAnnotations -- Annotations to add to the ServiceAccount if agents.rbac.create is true
    serviceAccountAnnotations: {}

  ## Provide Daemonset PodSecurityPolicy configuration
  podSecurity:
    podSecurityPolicy:
      # agents.podSecurity.podSecurityPolicy.create -- If true, create a PodSecurityPolicy resource for Agent pods
      create: false

    securityContextConstraints:
      # agents.podSecurity.securityContextConstraints.create -- If true, create a SecurityContextConstraints resource for Agent pods
      create: false

    # agents.podSecurity.seLinuxContext -- Provide seLinuxContext configuration for PSP/SCC
    # @default -- Must run as spc_t
    seLinuxContext:
      rule: MustRunAs
      seLinuxOptions:
        user: system_u
        role: system_r
        type: spc_t
        level: s0

    # agents.podSecurity.privileged -- If true, Allow to run privileged containers
    privileged: false

    # agents.podSecurity.capabilities -- Allowed capabilities
    ## capabilities must contain all agents.containers.*.securityContext.capabilities.
    capabilities:
      - SYS_ADMIN
      - SYS_RESOURCE
      - SYS_PTRACE
      - NET_ADMIN
      - NET_BROADCAST
      - NET_RAW
      - IPC_LOCK
      - CHOWN
      - AUDIT_CONTROL
      - AUDIT_READ

    # agents.podSecurity.allowedUnsafeSysctls -- Allowed unsafe sysclts
    allowedUnsafeSysctls: []

    # agents.podSecurity.volumes -- Allowed volumes types
    volumes:
      - configMap
      - downwardAPI
      - emptyDir
      - hostPath
      - secret

    # agents.podSecurity.seccompProfiles -- Allowed seccomp profiles
    seccompProfiles:
      - "runtime/default"
      - "localhost/system-probe"

    apparmor:
      # agents.podSecurity.apparmor.enabled -- If true, enable apparmor enforcement
      ## see: https://kubernetes.io/docs/tutorials/clusters/apparmor/
      enabled: false

    # agents.podSecurity.apparmorProfiles -- Allowed apparmor profiles
    apparmorProfiles:
      - "runtime/default"
      - "unconfined"

    # agents.podSecurity.defaultApparmor -- Default AppArmor profile for all containers but system-probe
    defaultApparmor: runtime/default

  containers:
    agent:
      # agents.containers.agent.env -- Additional environment variables for the agent container
      env: []

      # agents.containers.agent.envFrom -- Set environment variables specific to agent container from configMaps and/or secrets
      envFrom: []
      #   - configMapRef:
      #       name: <CONFIGMAP_NAME>
      #   - secretRef:
      #       name: <SECRET_NAME>

      # agents.containers.agent.logLevel -- Set logging verbosity, valid log levels are: trace, debug, info, warn, error, critical, and off
      ## If not set, fall back to the value of datadog.logLevel.
      logLevel:  # INFO

      # agents.containers.agent.resources -- Resource requests and limits for the agent container.
      resources: {}
      #  requests:
      #    cpu: 200m
      #    memory: 256Mi
      #  limits:
      #    cpu: 200m
      #    memory: 256Mi

      # agents.containers.agent.healthPort -- Port number to use in the node agent for the healthz endpoint
      healthPort: 5555

      # agents.containers.agent.livenessProbe -- Override default agent liveness probe settings
      # @default -- Every 15s / 6 KO / 1 OK
      livenessProbe:
        initialDelaySeconds: 15
        periodSeconds: 15
        timeoutSeconds: 5
        successThreshold: 1
        failureThreshold: 6

      # agents.containers.agent.readinessProbe -- Override default agent readiness probe settings
      # @default -- Every 15s / 6 KO / 1 OK
      readinessProbe:
        initialDelaySeconds: 15
        periodSeconds: 15
        timeoutSeconds: 5
        successThreshold: 1
        failureThreshold: 6

      # agents.containers.agent.securityContext -- Allows you to overwrite the default container SecurityContext for the agent container.
      securityContext: {}

      # agents.containers.agent.ports -- Allows to specify extra ports (hostPorts for instance) for this container
      ports: []

    processAgent:
      # agents.containers.processAgent.env -- Additional environment variables for the process-agent container
      env: []

      # agents.containers.processAgent.envFrom -- Set environment variables specific to process-agent from configMaps and/or secrets
      envFrom: []
      #   - configMapRef:
      #       name: <CONFIGMAP_NAME>
      #   - secretRef:
      #       name: <SECRET_NAME>

      # agents.containers.processAgent.logLevel -- Set logging verbosity, valid log levels are: trace, debug, info, warn, error, critical, and off
      ## If not set, fall back to the value of datadog.logLevel.
      logLevel:  # INFO

      # agents.containers.processAgent.resources -- Resource requests and limits for the process-agent container
      resources: {}
      #  requests:
      #    cpu: 100m
      #    memory: 200Mi
      #  limits:
      #    cpu: 100m
      #    memory: 200Mi

      # agents.containers.processAgent.securityContext -- Allows you to overwrite the default container SecurityContext for the process-agent container.
      securityContext: {}

      # agents.containers.processAgent.ports -- Allows to specify extra ports (hostPorts for instance) for this container
      ports: []

    traceAgent:
      # agents.containers.traceAgent.env -- Additional environment variables for the trace-agent container
      env:

      # agents.containers.traceAgent.envFrom -- Set environment variables specific to trace-agent from configMaps and/or secrets
      envFrom: []
      #   - configMapRef:
      #       name: <CONFIGMAP_NAME>
      #   - secretRef:
      #       name: <SECRET_NAME>

      # agents.containers.traceAgent.logLevel -- Set logging verbosity, valid log levels are: trace, debug, info, warn, error, critical, and off
      logLevel:  # INFO

      # agents.containers.traceAgent.resources -- Resource requests and limits for the trace-agent container
      resources: {}
      #  requests:
      #    cpu: 100m
      #    memory: 200Mi
      #  limits:
      #    cpu: 100m
      #    memory: 200Mi

      # agents.containers.traceAgent.livenessProbe -- Override default agent liveness probe settings
      # @default -- Every 15s
      livenessProbe:
        initialDelaySeconds: 15
        periodSeconds: 15
        timeoutSeconds: 5

      # agents.containers.traceAgent.securityContext -- Allows you to overwrite the default container SecurityContext for the trace-agent container.
      securityContext: {}

      # agents.containers.traceAgent.ports -- Allows to specify extra ports (hostPorts for instance) for this container
      ports: []

    systemProbe:
      # agents.containers.systemProbe.env -- Additional environment variables for the system-probe container
      env: []

      # agents.containers.systemProbe.envFrom -- Set environment variables specific to system-probe from configMaps and/or secrets
      envFrom: []
      #   - configMapRef:
      #       name: <CONFIGMAP_NAME>
      #   - secretRef:
      #       name: <SECRET_NAME>

      # agents.containers.systemProbe.logLevel -- Set logging verbosity, valid log levels are: trace, debug, info, warn, error, critical, and off.
      ## If not set, fall back to the value of datadog.logLevel.
      logLevel:  # INFO

      # agents.containers.systemProbe.resources -- Resource requests and limits for the system-probe container
      resources: {}
      #  requests:
      #    cpu: 100m
      #    memory: 200Mi
      #  limits:
      #    cpu: 100m
      #    memory: 200Mi

      # agents.containers.systemProbe.securityContext -- Allows you to overwrite the default container SecurityContext for the system-probe container.
      ## agents.podSecurity.capabilities must reflect the changed made in securityContext.capabilities.
      securityContext:
        privileged: false
        capabilities:
          add: ["SYS_ADMIN", "SYS_RESOURCE", "SYS_PTRACE", "NET_ADMIN", "NET_BROADCAST", "NET_RAW", "IPC_LOCK", "CHOWN"]

      # agents.containers.systemProbe.ports -- Allows to specify extra ports (hostPorts for instance) for this container
      ports: []

    securityAgent:
      # agents.containers.securityAgent.env -- Additional environment variables for the security-agent container
      env:

      # agents.containers.securityAgent.envFrom -- Set environment variables specific to security-agent from configMaps and/or secrets
      envFrom: []
      #   - configMapRef:
      #       name: <CONFIGMAP_NAME>
      #   - secretRef:
      #       name: <SECRET_NAME>

      # agents.containers.securityAgent.logLevel -- Set logging verbosity, valid log levels are: trace, debug, info, warn, error, critical, and off
      ## If not set, fall back to the value of datadog.logLevel.
      logLevel:  # INFO

      # agents.containers.securityAgent.resources -- Resource requests and limits for the security-agent container
      resources: {}
      #  requests:
      #    cpu: 100m
      #    memory: 200Mi
      #  limits:
      #    cpu: 100m
      #    memory: 200Mi

      # agents.containers.securityAgent.ports -- Allows to specify extra ports (hostPorts for instance) for this container
      ports: []

    initContainers:
      # agents.containers.initContainers.resources -- Resource requests and limits for the init containers
      resources: {}
      #  requests:
      #    cpu: 100m
      #    memory: 200Mi
      #  limits:
      #    cpu: 100m
      #    memory: 200Mi

  # agents.volumes -- Specify additional volumes to mount in the dd-agent container
  volumes: []
  #   - hostPath:
  #       path: <HOST_PATH>
  #     name: <VOLUME_NAME>

  # agents.volumeMounts -- Specify additional volumes to mount in all containers of the agent pod
  volumeMounts: []
  #   - name: <VOLUME_NAME>
  #     mountPath: <CONTAINER_PATH>
  #     readOnly: true

  # agents.useHostNetwork -- Bind ports on the hostNetwork
  ## Useful for CNI networking where hostPort might
  ## not be supported. The ports need to be available on all hosts. It Can be
  ## used for custom metrics instead of a service endpoint.
  ##
  ## WARNING: Make sure that hosts using this are properly firewalled otherwise
  ## metrics and traces are accepted from any host able to connect to this host.
  useHostNetwork: false

  # agents.dnsConfig -- specify dns configuration options for datadog cluster agent containers e.g ndots
  ## ref: https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/#pod-dns-config
  dnsConfig: {}
  #  options:
  #  - name: ndots
  #    value: "1"

  # agents.daemonsetAnnotations -- Annotations to add to the DaemonSet
  daemonsetAnnotations: {}
  #   key: "value"


  podAnnotations: {}
  #   <POD_ANNOTATION>: '[{"key": "<KEY>", "value": "<VALUE>"}]'

  # agents.tolerations -- Allow the DaemonSet to schedule on tainted nodes (requires Kubernetes >= 1.6)
  tolerations: []

  # agents.nodeSelector -- Allow the DaemonSet to schedule on selected nodes
  ## Ref: https://kubernetes.io/docs/user-guide/node-selection/
  nodeSelector: {}

  # agents.affinity -- Allow the DaemonSet to schedule using affinity rules
  ## Ref: https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#affinity-and-anti-affinity
  affinity: {}

  # agents.updateStrategy -- Allow the DaemonSet to perform a rolling update on helm update
  ## ref: https://kubernetes.io/docs/tasks/manage-daemon/update-daemon-set/
  updateStrategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1

  # agents.priorityClassCreate -- Creates a priorityClass for the Datadog Agent's Daemonset pods.
  priorityClassCreate: false

  # agents.priorityClassName -- Sets PriorityClassName if defined
  priorityClassName:

  # agents.priorityClassValue -- Value used to specify the priority of the scheduling of Datadog Agent's Daemonset pods.
  ## The PriorityClass uses PreemptLowerPriority.
  priorityClassValue: 1000000000

  # agents.podLabels -- Sets podLabels if defined
  # Note: These labels are also used as label selectors so they are immutable.
  podLabels: {}

  # agents.additionalLabels -- Adds labels to the Agent daemonset and pods
  additionalLabels: {}
    # key: "value"


  useConfigMap:  # false

  customAgentConfig: {}
  #   # Autodiscovery for Kubernetes
  #   listeners:
  #     - name: kubelet
  #   config_providers:
  #     - name: kubelet
  #       polling: true
  #     # needed to support legacy docker label config templates
  #     - name: docker
  #       polling: true
  #
  #   # Enable java cgroup handling. Only one of those options should be enabled,
  #   # depending on the agent version you are using along that chart.
  #
  #   # agent version < 6.15
  #   # jmx_use_cgroup_memory_limit: true
  #
  #   # agent version >= 6.15
  #   # jmx_use_container_support: true

  networkPolicy:
    # agents.networkPolicy.create -- If true, create a NetworkPolicy for the agents.
    # DEPRECATED. Use datadog.networkPolicy.create instead
    create: false

  localService:
    # agents.localService.overrideName -- Name of the internal traffic service to target the agent running on the local node
    overrideName: ""

    forceLocalServiceEnabled: false


clusterChecksRunner:

  enabled: true

  ## Define the Datadog image to work with.
  image:

    name: agent

    # clusterChecksRunner.image.tag -- Define the Agent version to use
    tag: 7.33.0

    # clusterChecksRunner.image.tagSuffix -- Suffix to append to Agent tag
    ## Ex:
    ##  jmx        to enable jmx fetch collection
    ##  servercore to get Windows images based on servercore
    tagSuffix: ""

    # clusterChecksRunner.image.repository -- Override default registry + image.name for Cluster Check Runners
    repository:

    # clusterChecksRunner.image.pullPolicy -- Datadog Agent image pull policy
    pullPolicy: IfNotPresent


    pullSecrets: []
    #   - name: "<REG_SECRET>"

  # clusterChecksRunner.createPodDisruptionBudget -- Create the pod disruption budget to apply to the cluster checks agents
  createPodDisruptionBudget: true

  # Provide Cluster Checks Deployment pods RBAC configuration
  rbac:
    # clusterChecksRunner.rbac.create -- If true, create & use RBAC resources
    create: true

    # clusterChecksRunner.rbac.dedicated -- If true, use a dedicated RBAC resource for the cluster checks agent(s)
    dedicated: false

    # clusterChecksRunner.rbac.serviceAccountAnnotations -- Annotations to add to the ServiceAccount if clusterChecksRunner.rbac.dedicated is true
    serviceAccountAnnotations: {}

    # clusterChecksRunner.rbac.serviceAccountName -- Specify a preexisting ServiceAccount to use if clusterChecksRunner.rbac.create is false
    serviceAccountName: default

  # clusterChecksRunner.replicas -- Number of Cluster Checks Runner instances
  ## If you want to deploy the clusterChecks agent in HA, keep at least clusterChecksRunner.replicas set to 2.
  ## And increase the clusterChecksRunner.replicas according to the number of Cluster Checks.
  replicas: 2

  # clusterChecksRunner.resources -- Datadog clusterchecks-agent resource requests and limits.
  resources: {}
  # requests:
  #   cpu: 200m
  #   memory: 500Mi
  # limits:
  #   cpu: 200m
  #   memory: 500Mi


  affinity: {}

  # clusterChecksRunner.strategy -- Allow the ClusterChecks deployment to perform a rolling update on helm update
  ## ref: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#strategy
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 2
      maxUnavailable: 1

  # clusterChecksRunner.dnsConfig -- specify dns configuration options for datadog cluster agent containers e.g ndots
  ## ref: https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/#pod-dns-config
  dnsConfig: {}
  #  options:
  #  - name: ndots
  #    value: "1"

  # clusterChecksRunner.priorityClassName -- Name of the priorityClass to apply to the Cluster checks runners
  priorityClassName:  # system-cluster-critical

  # clusterChecksRunner.nodeSelector -- Allow the ClusterChecks Deployment to schedule on selected nodes
  ## Ref: https://kubernetes.io/docs/user-guide/node-selection/
  #
  nodeSelector: {}

  # clusterChecksRunner.tolerations -- Tolerations for pod assignment
  ## Ref: https://kubernetes.io/docs/concepts/configuration/taint-and-toleration/
  #
  tolerations: []

  # clusterChecksRunner.healthPort -- Port number to use in the Cluster Checks Runner for the healthz endpoint
  healthPort: 5557

  # clusterChecksRunner.livenessProbe -- Override default agent liveness probe settings
  # @default -- Every 15s / 6 KO / 1 OK
  ## In case of issues with the probe, you can disable it with the
  ## following values, to allow easier investigating:
  #
  # livenessProbe:
  #   exec:
  #     command: ["/bin/true"]
  #
  livenessProbe:
    initialDelaySeconds: 15
    periodSeconds: 15
    timeoutSeconds: 5
    successThreshold: 1
    failureThreshold: 6

  # clusterChecksRunner.readinessProbe -- Override default agent readiness probe settings
  # @default -- Every 15s / 6 KO / 1 OK
  ## In case of issues with the probe, you can disable it with the
  ## following values, to allow easier investigating:
  #
  # readinessProbe:
  #   exec:
  #     command: ["/bin/true"]
  #
  readinessProbe:
    initialDelaySeconds: 15
    periodSeconds: 15
    timeoutSeconds: 5
    successThreshold: 1
    failureThreshold: 6


  deploymentAnnotations: {}
  #   key: "value"


  podAnnotations: {}
  #   key: "value"

  # clusterChecksRunner.env -- Environment variables specific to Cluster Checks Runner
  ## ref: https://github.com/DataDog/datadog-agent/tree/main/Dockerfiles/agent#environment-variables
  env: []
  #   - name: <ENV_VAR_NAME>
  #     value: <ENV_VAR_VALUE>

  # clusterChecksRunner.envFrom -- Set environment variables specific to Cluster Checks Runner from configMaps and/or secrets
  ## envFrom to pass configmaps or secrets as environment
  ## ref: https://github.com/DataDog/datadog-agent/tree/main/Dockerfiles/agent#environment-variables
  envFrom: []
  #   - configMapRef:
  #       name: <CONFIGMAP_NAME>
  #   - secretRef:
  #       name: <SECRET_NAME>

  # clusterChecksRunner.volumes -- Specify additional volumes to mount in the cluster checks container
  volumes: []
  #   - hostPath:
  #       path: <HOST_PATH>
  #     name: <VOLUME_NAME>

  # clusterChecksRunner.volumeMounts -- Specify additional volumes to mount in the cluster checks container
  volumeMounts: []
  #   - name: <VOLUME_NAME>
  #     mountPath: <CONTAINER_PATH>
  #     readOnly: true

  networkPolicy:
    # clusterChecksRunner.networkPolicy.create -- If true, create a NetworkPolicy for the cluster checks runners.
    # DEPRECATED. Use datadog.networkPolicy.create instead
    create: false

  # clusterChecksRunner.additionalLabels -- Adds labels to the cluster checks runner deployment and pods
  additionalLabels: {}
    # key: "value"

  # clusterChecksRunner.securityContext -- Allows you to overwrite the default PodSecurityContext on the clusterchecks pods.
  securityContext: {}

  # clusterChecksRunner.ports -- Allows to specify extra ports (hostPorts for instance) for this container
  ports: []



datadog-crds:
  crds:
    # datadog-crds.crds.datadogMetrics -- Set to true to deploy the DatadogMetrics CRD
    datadogMetrics: true

kube-state-metrics:
  rbac:
    # kube-state-metrics.rbac.create -- If true, create & use RBAC resources
    create: false

  serviceAccount:
    # kube-state-metrics.serviceAccount.create -- If true, create ServiceAccount, require rbac kube-state-metrics.rbac.create true
    create: false

    # kube-state-metrics.serviceAccount.name -- The name of the ServiceAccount to use.
    ## If not set and create is true, a name is generated using the fullname template
    name:

  # kube-state-metrics.resources -- Resource requests and limits for the kube-state-metrics container.
  resources: {}
  #   requests:
  #     cpu: 200m
  #     memory: 256Mi
  #   limits:
  #     cpu: 200m
  #     memory: 256Mi

  # kube-state-metrics.nodeSelector -- Node selector for KSM. KSM only supports Linux.
  nodeSelector:
    kubernetes.io/os: linux

  # # kube-state-metrics.image -- Override default image information for the kube-state-metrics container.
  # image:
  #  # kube-state-metrics.repository -- Override default image registry for the kube-state-metrics container.
  #  repository: k8s.gcr.io/kube-state-metrics/kube-state-metrics
  #  # kube-state-metrics.tag -- Override default image tag for the kube-state-metrics container.
  #  tag: v1.9.8
  #  # kube-state-metrics.pullPolicy -- Override default image pullPolicy for the kube-state-metrics container.
  #  pullPolicy: IfNotPresent

providers:
  gke:
    # providers.gke.autopilot -- Enables Datadog Agent deployment on GKE Autopilot
    autopilot: false

  eks:
    ec2:

      useHostnameFromFile: false
EOF


kubectl create namespace "datadog" --dry-run=client -o yaml | kubectl apply -f -
helm repo add datadog https://helm.datadoghq.com
helm repo update

helm upgrade --install datadog-agent datadog/datadog \
  -f datadog/values.yaml \
  --wait \
  --namespace datadog \
  --set datadog.apiKey=$DATADOG_API_KEY \
  --set datadog.appKey=$DATADOG_APP_KEY \
  --set datadog.clusterName=$CLUSTER \
  --set datadog.logLevel=INFO \
  --set datadog.tags=["cluster:$CLUSTER"] \
  --set dogstatsd.tags=["cluster:$CLUSTER"] \
  --set clusteragent.image.tag=$DATADOG_CLUSTER_AGENT_VERSION \
  --set agent.image.tag=$DATADOG_AGENT_VERSION \
  --set targetSystem=linux
