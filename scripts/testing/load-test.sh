#!/bin/bash

# Load Testing Script for Inspira Platform
# This script uses Apache JMeter to perform load testing on the Inspira services

set -e

# Default values
DURATION=300  # Test duration in seconds
THREADS=50    # Number of concurrent users
RAMP_UP=60    # Ramp-up period in seconds
TEST_HOST="localhost"
TEST_PORT="8000"
TEST_PLAN="load-test-plan.jmx"
RESULTS_DIR="load-test-results"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --duration=*)
      DURATION="${1#*=}"
      shift
      ;;
    --threads=*)
      THREADS="${1#*=}"
      shift
      ;;
    --ramp-up=*)
      RAMP_UP="${1#*=}"
      shift
      ;;
    --host=*)
      TEST_HOST="${1#*=}"
      shift
      ;;
    --port=*)
      TEST_PORT="${1#*=}"
      shift
      ;;
    --help)
      echo "Usage: $0 [options]"
      echo "Options:"
      echo "  --duration=SECONDS    Test duration in seconds (default: 300)"
      echo "  --threads=NUMBER      Number of concurrent users (default: 50)"
      echo "  --ramp-up=SECONDS     Ramp-up period in seconds (default: 60)"
      echo "  --host=HOSTNAME       Target host (default: localhost)"
      echo "  --port=PORT           Target port (default: 8000)"
      echo "  --help                Display this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Check if JMeter is installed
if ! command -v jmeter &> /dev/null; then
  echo "Apache JMeter is not installed. Please install it first."
  echo "Visit https://jmeter.apache.org/download_jmeter.cgi for download instructions."
  exit 1
fi

# Create results directory if it doesn't exist
mkdir -p "$RESULTS_DIR"

# Generate timestamp for result files
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
RESULT_FILE="$RESULTS_DIR/load_test_result_${TIMESTAMP}.jtl"
REPORT_DIR="$RESULTS_DIR/report_${TIMESTAMP}"

echo "========================================="
echo "Starting Load Test with the following parameters:"
echo "- Duration: $DURATION seconds"
echo "- Concurrent Users: $THREADS"
echo "- Ramp-up Period: $RAMP_UP seconds"
echo "- Target: http://$TEST_HOST:$TEST_PORT"
echo "========================================="

# Check if the test plan exists or create a basic one
if [ ! -f "$TEST_PLAN" ]; then
  echo "Creating basic JMeter test plan..."
  
  cat > "$TEST_PLAN" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<jmeterTestPlan version="1.2" properties="5.0">
  <hashTree>
    <TestPlan guiclass="TestPlanGui" testclass="TestPlan" testname="Inspira Load Test Plan">
      <stringProp name="TestPlan.comments"></stringProp>
      <boolProp name="TestPlan.functional_mode">false</boolProp>
      <boolProp name="TestPlan.tearDown_on_shutdown">true</boolProp>
      <boolProp name="TestPlan.serialize_threadgroups">false</boolProp>
      <elementProp name="TestPlan.user_defined_variables" elementType="Arguments">
        <collectionProp name="Arguments.arguments"/>
      </elementProp>
    </TestPlan>
    <hashTree>
      <ThreadGroup guiclass="ThreadGroupGui" testclass="ThreadGroup" testname="Inspira Users">
        <stringProp name="ThreadGroup.on_sample_error">continue</stringProp>
        <elementProp name="ThreadGroup.main_controller" elementType="LoopController">
          <boolProp name="LoopController.continue_forever">false</boolProp>
          <intProp name="LoopController.loops">-1</intProp>
        </elementProp>
        <stringProp name="ThreadGroup.num_threads">${__P(threads,50)}</stringProp>
        <stringProp name="ThreadGroup.ramp_time">${__P(rampUp,60)}</stringProp>
        <boolProp name="ThreadGroup.scheduler">true</boolProp>
        <stringProp name="ThreadGroup.duration">${__P(duration,300)}</stringProp>
        <stringProp name="ThreadGroup.delay">0</stringProp>
      </ThreadGroup>
      <hashTree>
        <ConfigTestElement guiclass="HttpDefaultsGui" testclass="ConfigTestElement" testname="HTTP Request Defaults">
          <elementProp name="HTTPsampler.Arguments" elementType="Arguments">
            <collectionProp name="Arguments.arguments"/>
          </elementProp>
          <stringProp name="HTTPsampler.domain">${__P(host,localhost)}</stringProp>
          <stringProp name="HTTPsampler.port">${__P(port,8000)}</stringProp>
          <stringProp name="HTTPsampler.protocol">http</stringProp>
          <stringProp name="HTTPsampler.contentEncoding"></stringProp>
          <stringProp name="HTTPsampler.path"></stringProp>
        </ConfigTestElement>
        <hashTree/>
        
        <!-- API Gateway Health Check -->
        <HTTPSamplerProxy guiclass="HttpTestSampleGui" testclass="HTTPSamplerProxy" testname="API Gateway Health">
          <elementProp name="HTTPsampler.Arguments" elementType="Arguments">
            <collectionProp name="Arguments.arguments"/>
          </elementProp>
          <stringProp name="HTTPsampler.path">/api/gateway/health</stringProp>
          <stringProp name="HTTPsampler.method">GET</stringProp>
          <boolProp name="HTTPsampler.follow_redirects">true</boolProp>
          <boolProp name="HTTPsampler.auto_redirects">false</boolProp>
          <boolProp name="HTTPsampler.use_keepalive">true</boolProp>
          <boolProp name="HTTPsampler.DO_MULTIPART_POST">false</boolProp>
        </HTTPSamplerProxy>
        <hashTree/>
        
        <!-- User Service Health Check -->
        <HTTPSamplerProxy guiclass="HttpTestSampleGui" testclass="HTTPSamplerProxy" testname="User Service Health">
          <elementProp name="HTTPsampler.Arguments" elementType="Arguments">
            <collectionProp name="Arguments.arguments"/>
          </elementProp>
          <stringProp name="HTTPsampler.path">/api/users/health</stringProp>
          <stringProp name="HTTPsampler.method">GET</stringProp>
          <boolProp name="HTTPsampler.follow_redirects">true</boolProp>
          <boolProp name="HTTPsampler.auto_redirects">false</boolProp>
          <boolProp name="HTTPsampler.use_keepalive">true</boolProp>
          <boolProp name="HTTPsampler.DO_MULTIPART_POST">false</boolProp>
        </HTTPSamplerProxy>
        <hashTree/>
        
        <!-- Content Service Health Check -->
        <HTTPSamplerProxy guiclass="HttpTestSampleGui" testclass="HTTPSamplerProxy" testname="Content Service Health">
          <elementProp name="HTTPsampler.Arguments" elementType="Arguments">
            <collectionProp name="Arguments.arguments"/>
          </elementProp>
          <stringProp name="HTTPsampler.path">/api/content/health</stringProp>
          <stringProp name="HTTPsampler.method">GET</stringProp>
          <boolProp name="HTTPsampler.follow_redirects">true</boolProp>
          <boolProp name="HTTPsampler.auto_redirects">false</boolProp>
          <boolProp name="HTTPsampler.use_keepalive">true</boolProp>
          <boolProp name="HTTPsampler.DO_MULTIPART_POST">false</boolProp>
        </HTTPSamplerProxy>
        <hashTree/>
        
        <!-- Media Service Health Check -->
        <HTTPSamplerProxy guiclass="HttpTestSampleGui" testclass="HTTPSamplerProxy" testname="Media Service Health">
          <elementProp name="HTTPsampler.Arguments" elementType="Arguments">
            <collectionProp name="Arguments.arguments"/>
          </elementProp>
          <stringProp name="HTTPsampler.path">/api/media/health</stringProp>
          <stringProp name="HTTPsampler.method">GET</stringProp>
          <boolProp name="HTTPsampler.follow_redirects">true</boolProp>
          <boolProp name="HTTPsampler.auto_redirects">false</boolProp>
          <boolProp name="HTTPsampler.use_keepalive">true</boolProp>
          <boolProp name="HTTPsampler.DO_MULTIPART_POST">false</boolProp>
        </HTTPSamplerProxy>
        <hashTree/>
        
        <!-- User Profile Creation -->
        <HTTPSamplerProxy guiclass="HttpTestSampleGui" testclass="HTTPSamplerProxy" testname="Create User Profile">
          <elementProp name="HTTPsampler.Arguments" elementType="Arguments">
            <collectionProp name="Arguments.arguments"/>
          </elementProp>
          <stringProp name="HTTPsampler.path">/api/users/profiles/debug/direct-create</stringProp>
          <stringProp name="HTTPsampler.method">POST</stringProp>
          <boolProp name="HTTPsampler.follow_redirects">true</boolProp>
          <boolProp name="HTTPsampler.auto_redirects">false</boolProp>
          <boolProp name="HTTPsampler.use_keepalive">true</boolProp>
          <boolProp name="HTTPsampler.DO_MULTIPART_POST">false</boolProp>
          <elementProp name="HTTPsampler.Files" elementType="HTTPFileArgs">
            <collectionProp name="HTTPFileArgs.files"/>
          </elementProp>
          <stringProp name="HTTPsampler.contentEncoding">UTF-8</stringProp>
          <stringProp name="HTTPsampler.implementation">HttpClient4</stringProp>
          <stringProp name="HTTPsampler.connect_timeout">60000</stringProp>
          <stringProp name="HTTPsampler.response_timeout">60000</stringProp>
        </HTTPSamplerProxy>
        <hashTree>
          <HeaderManager guiclass="HeaderPanel" testclass="HeaderManager" testname="HTTP Header Manager">
            <collectionProp name="HeaderManager.headers">
              <elementProp name="" elementType="Header">
                <stringProp name="Header.name">Content-Type</stringProp>
                <stringProp name="Header.value">application/json</stringProp>
              </elementProp>
            </collectionProp>
          </HeaderManager>
          <hashTree/>
          <JSR223PreProcessor guiclass="TestBeanGUI" testclass="JSR223PreProcessor" testname="JSR223 PreProcessor">
            <stringProp name="scriptLanguage">groovy</stringProp>
            <stringProp name="parameters"></stringProp>
            <stringProp name="filename"></stringProp>
            <stringProp name="cacheKey">true</stringProp>
            <stringProp name="script">import groovy.json.JsonBuilder;

def uuid = UUID.randomUUID().toString();
def profile = [
    auth0Id: "load-test-" + uuid,
    displayName: "Load Test User " + uuid.substring(0, 8),
    avatarUrl: "https://example.com/avatar-" + uuid.substring(0, 8) + ".png"
];

def json = new JsonBuilder(profile).toPrettyString();
sampler.addNonEncodedArgument("", json, "");
</stringProp>
          </JSR223PreProcessor>
          <hashTree/>
        </hashTree>
        
        <!-- Results -->
        <ResultCollector guiclass="ViewResultsFullVisualizer" testclass="ResultCollector" testname="View Results Tree">
          <boolProp name="ResultCollector.error_logging">false</boolProp>
          <objProp>
            <name>saveConfig</name>
            <value class="SampleSaveConfiguration">
              <time>true</time>
              <latency>true</latency>
              <timestamp>true</timestamp>
              <success>true</success>
              <label>true</label>
              <code>true</code>
              <message>true</message>
              <threadName>true</threadName>
              <dataType>true</dataType>
              <encoding>false</encoding>
              <assertions>true</assertions>
              <subresults>true</subresults>
              <responseData>false</responseData>
              <samplerData>false</samplerData>
              <xml>false</xml>
              <fieldNames>true</fieldNames>
              <responseHeaders>false</responseHeaders>
              <requestHeaders>false</requestHeaders>
              <responseDataOnError>false</responseDataOnError>
              <saveAssertionResultsFailureMessage>true</saveAssertionResultsFailureMessage>
              <assertionsResultsToSave>0</assertionsResultsToSave>
              <bytes>true</bytes>
              <sentBytes>true</sentBytes>
              <url>true</url>
              <threadCounts>true</threadCounts>
              <idleTime>true</idleTime>
              <connectTime>true</connectTime>
            </value>
          </objProp>
          <stringProp name="filename"></stringProp>
        </ResultCollector>
        <hashTree/>
        
        <ResultCollector guiclass="SummaryReport" testclass="ResultCollector" testname="Summary Report">
          <boolProp name="ResultCollector.error_logging">false</boolProp>
          <objProp>
            <name>saveConfig</name>
            <value class="SampleSaveConfiguration">
              <time>true</time>
              <latency>true</latency>
              <timestamp>true</timestamp>
              <success>true</success>
              <label>true</label>
              <code>true</code>
              <message>true</message>
              <threadName>true</threadName>
              <dataType>true</dataType>
              <encoding>false</encoding>
              <assertions>true</assertions>
              <subresults>true</subresults>
              <responseData>false</responseData>
              <samplerData>false</samplerData>
              <xml>false</xml>
              <fieldNames>true</fieldNames>
              <responseHeaders>false</responseHeaders>
              <requestHeaders>false</requestHeaders>
              <responseDataOnError>false</responseDataOnError>
              <saveAssertionResultsFailureMessage>true</saveAssertionResultsFailureMessage>
              <assertionsResultsToSave>0</assertionsResultsToSave>
              <bytes>true</bytes>
              <sentBytes>true</sentBytes>
              <url>true</url>
              <threadCounts>true</threadCounts>
              <idleTime>true</idleTime>
              <connectTime>true</connectTime>
            </value>
          </objProp>
          <stringProp name="filename"></stringProp>
        </ResultCollector>
        <hashTree/>
      </hashTree>
    </hashTree>
  </hashTree>
</jmeterTestPlan>
EOF
  echo "Basic JMeter test plan created: $TEST_PLAN"
fi

# Run JMeter test
echo "Running JMeter test..."
jmeter -n -t "$TEST_PLAN" \
  -Jthreads="$THREADS" \
  -JrampUp="$RAMP_UP" \
  -Jduration="$DURATION" \
  -Jhost="$TEST_HOST" \
  -Jport="$TEST_PORT" \
  -l "$RESULT_FILE" \
  -e -o "$REPORT_DIR"

echo "========================================="
echo "Load test completed!"
echo "Results saved to: $RESULT_FILE"
echo "HTML report generated at: $REPORT_DIR"
echo "=========================================" 