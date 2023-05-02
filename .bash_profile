
# source bashrc
if [ -f ~/.bashrc ]; then
    source ~/.bashrc
fi

export JAVA_TOOL_OPTIONS="-Djavax.net.ssl.trustStore=/etc/ssl/java/cacerts"
export GRADLE_OPTS="$GRADLE_OPTS -Djavax.net.ssl.trustStore=/etc/ssl/java/cacerts"

export SPARK_HOME=/usr/local/Cellar/apache-spark@3.1.2/3.1.2/libexec
export PYTHONPATH=/usr/local/Cellar/apache-spark@3.1.2/3.1.2/libexec/python/:$PYTHONP$

export SSL_CERTIFICATE_PATH="/usr/local/etc/openssl/certs/BankOfNewZealandRootCertAuthority.pem"

export JAVA_HOME="/Library/Java/JavaVirtualMachines/adoptopenjdk-8.jdk/Contents/Home"
export ANDROID_HOME="/Users/793411/Library/Android/sdk"
#export CONFLUENT_HOME="/Users/793411/Library/confluent-7.1.0"
export SBT_HOME=/usr/local/opt/sbt
export PATH=$ANDROID_HOME/platform-tools:/usr/local/bin:~/.npm-global/bin:$JAVA_HOME:$SBT_HOME/bin:$PATH

alias ocpt='oc login app.nz.thenational.com:8443 && oc whoami -t'
alias kafka='confluent local services'

alias fxscreens='displayplacer "id:B6C79EC1-C746-EB41-1598-E1825D459158 res:1680x1050 color_depth:4 scaling:on origin:(0,0) degree:0" "id:8731C42F-2C6E-1E93-08BD-B5AAC56C6CCF res:1920x1080 hz:60 color_depth:4 scaling:off origin:(906,-1080) degree:0" "id:CFEC8771-642B-32A4-6081-EC264628DB33 res:1920x1080 hz:60 color_depth:4 scaling:off origin:(-1014,-1080) degree:0"'
