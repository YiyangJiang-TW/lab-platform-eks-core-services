---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app.kubernetes.io/name: aws-efs-csi-driver
  name: efs-csi-controller
  namespace: kube-system
spec:
  replicas: 2
  selector:
    matchLabels:
      app: efs-csi-controller
      app.kubernetes.io/instance: kustomize
      app.kubernetes.io/name: aws-efs-csi-driver
  template:
    metadata:
      labels:
        app: efs-csi-controller
        app.kubernetes.io/instance: kustomize
        app.kubernetes.io/name: aws-efs-csi-driver
    spec:
      containers:
      - args:
        - --endpoint=$(CSI_ENDPOINT)
        - --logtostderr
        - --v=2
        - --delete-access-point-root-dir=false
        env:
        - name: CSI_ENDPOINT
          value: unix:///var/lib/csi/sockets/pluginproxy/csi.sock
        image: 602401143452.dkr.ecr.us-west-2.amazonaws.com/eks/aws-efs-csi-driver:vEFS_CSI_DRIVER_VERSION
        imagePullPolicy: IfNotPresent
        livenessProbe:
          failureThreshold: 5
          httpGet:
            path: /healthz
            port: healthz
          initialDelaySeconds: 10
          periodSeconds: 10
          timeoutSeconds: 3
        name: efs-plugin
        ports:
        - containerPort: 9909
          name: healthz
          protocol: TCP
        securityContext:
          privileged: true
        volumeMounts:
        - mountPath: /var/lib/csi/sockets/pluginproxy/
          name: socket-dir
      - args:
        - --csi-address=$(ADDRESS)
        - --v=2
        - --feature-gates=Topology=true
        - --extra-create-metadata
        - --leader-election
        env:
        - name: ADDRESS
          value: /var/lib/csi/sockets/pluginproxy/csi.sock
        image: 602401143452.dkr.ecr.us-west-2.amazonaws.com/eks/csi-provisioner:vCSI_PROVISIONER_VERSION
        imagePullPolicy: IfNotPresent
        name: csi-provisioner
        volumeMounts:
        - mountPath: /var/lib/csi/sockets/pluginproxy/
          name: socket-dir
      - args:
        - --csi-address=/csi/csi.sock
        - --health-port=9909
        image: 602401143452.dkr.ecr.us-west-2.amazonaws.com/eks/livenessprobe:vLIVENESS_PROBE_VERSION
        imagePullPolicy: IfNotPresent
        name: liveness-probe
        volumeMounts:
        - mountPath: /csi
          name: socket-dir
      hostNetwork: true
      nodeSelector:
        kubernetes.io/os: linux
      priorityClassName: system-cluster-critical
      serviceAccountName: efs-csi-controller-sa
      volumes:
      - emptyDir: {}
        name: socket-dir