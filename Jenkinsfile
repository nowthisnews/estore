// -*- mode: groovy -*-
serviceName = 'estore'

def ntp

node('master') {
  fileLoader.withGit('git@github.com:nowthisnews/jenkins-pipeline', 'v0.1.23') {
    ntp = fileLoader.load('nt_pipeline.groovy')
  }

  if(ntp.lastCommitAuthorNotEqTo('jenkins@nowth.is')) {
    ntp.hurtleRelease()
    ntp.rubyGemCreateDockerfile('2.4.2')
    ntp.rubyRunUnitTestsWithPostgress(serviceName)
    ntp.rubyGemPushToGemstash(serviceName, ntp.gitCommit())
    ntp.gitTryPublishTags(serviceName)
  }
}
