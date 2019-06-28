import java.text.SimpleDateFormat
//#################################

def repoSync(fullClean, fullReset, manifestRepo, manifestRev, manifestPath){
    checkout changelog: true, poll: true, scm: [$class: 'RepoScm', currentBranch: true, \
        forceSync: true, jobs: 4, manifestBranch: manifestRev, \
        manifestFile: manifestPath, manifestRepositoryUrl: manifestRepo, \
        quiet: false, resetFirst: fullClean, resetFirst: fullReset]
} 
//#################################

node('jolin') {
	stage('Environment'){
		def dateFormat = new SimpleDateFormat("yyyyMMdd_HHmm")
        def date = new Date()

        env.V_RELEASE_TIME = dateFormat.format(date)
        env.V_RELEASE_DIR = "release"
        env.PATH = "/sbin:" + env.PATH

		if(!env.V_BOARD){
            env.V_BOARD = "rk3399"
        }
        if(!env.V_KERNEL_CONFIG){
            env.V_KERNEL_CONFIG = "rockchip_defconfig"
        }
        if(!env.V_LUNCH_VARIANT){
            env.V_LUNCH_VARIANT = "userdebug"
        }
        if(!env.V_ARCH){
            env.V_ARCH = "arm64"
        }

		dir('build-environment') {
			checkout changelog: false, poll: false, scm: scm
		}
	}

 	def uid = sh (returnStdout: true, script: 'id -u').trim()
    def gid = sh (returnStdout: true, script: 'id -g').trim()
    def environment = docker.build('android-builder:9.x', "--build-arg USER_ID=${uid} --build-arg GROUP_ID=${gid} build-environment")

    environment.inside {
        def mVendorList = env.V_VENDOR.split(" ")
        def mLunchList  = env.V_LUNCHS.split(" ")

		stage('repo') {
		    repoSync(true, true, env.V_REPO_URL, env.V_REPO_BRANCH, env.V_REPO_XML)
		}
	    stage('uboot'){sh '''#!/bin/bash
	    		#uboot
				cd u-boot
				make distclean
				make mrproper
				./make.sh "$V_BOARD"
				cd -
	    	'''
	    }
        stage('init'){sh '''#!/bin/bash
            cd kernel
            make distclean
            make ARCH="$V_ARCH" "$V_KERNEL_CONFIG"
            cd -

            rm rockdev
            ln -s -f RKTools/linux/Linux_Pack_Firmware/rockdev/ rockdev

            rm -rf ${V_RELEASE_DIR}
            mkdir -p ${V_RELEASE_DIR}

	    	'''
            if (params.FULL_CLEAN_ANDROID){
		        sh '''#!/bin/bash
		            rm -rf out/target
		        '''
		    }
	    }
	    for(vendor in mVendorList){
            withEnv(["VENDOR_TMP=" + vendor]){
                stage('kernel-' + vendor){sh '''#!/bin/bash
                    cd kernel
                    make ARCH="$V_ARCH" ${V_BOARD}-${VENDOR_TMP}.img -j16
                    cp resource.img resource-${VENDOR_TMP}.img
                    '''
                }
            }
        }
	    for(lunch in mLunchList){
			withEnv(["LUNCH_TMP=" + lunch]){
				stage(lunch){sh '''#!/bin/bash
                        rm -rf out/target/product/${LUNCH_TMP}/root
                        rm -rf out/target/product/${LUNCH_TMP}/system
                        rm -rf out/target/product/${LUNCH_TMP}/recovery

                        . build/envsetup.sh
                        lunch ${LUNCH_TMP}-${V_LUNCH_VARIANT}
                        make -j16
					'''
				}
			}

			for(vendor in mVendorList){
				withEnv(["LUNCH_TMP=" + lunch, "VENDOR_TMP=" + vendor]){
					stage('image-' + lunch + '-' + vendor){sh '''#!/bin/bash
                            . build/envsetup.sh
                            lunch ${LUNCH_TMP}-${V_LUNCH_VARIANT}

                            cd kernel
                            cp -f resource-${VENDOR_TMP}.img resource.img
                            cd -

                            if [ "true" == "${V_ANDROID_RESOURCE}" ];then
                                rm out/target/product/${LUNCH_TMP}/boot.img
                                make bootimage -j8
                            fi
                            ./mkimage.sh

                            cd rockdev
                            rm -f Image
                            ln -s -f Image-${LUNCH_TMP} Image
                            ./mkupdate.sh
                            ./android-gpt.sh
                            cd -

                            commitId=`git -C .repo/manifests rev-parse --short HEAD`
                            platform=`get_build_var PLATFORM_VERSION`
                            release_name="android${platform}-${LUNCH_TMP}-${VENDOR_TMP}-${V_RELEASE_TIME}_${commitId}"

                            echo "android${platform}-${V_RELEASE_TIME}_${commitId}" > github-tag

                            mv rockdev/update.img    $V_RELEASE_DIR/${release_name}-rkupdate.img
                            mv rockdev/Image/gpt.img $V_RELEASE_DIR/${release_name}-gpt.img

                            cd ${V_RELEASE_DIR}
                            md5sum ${release_name}-rkupdate.img >> md5
                            md5sum ${release_name}-gpt.img >> md5

                            zip ${release_name}-rkupdate.zip ${release_name}-rkupdate.img
                            zip ${release_name}-gpt.zip ${release_name}-gpt.img
                            rm -f *.img
                            cd -

                            cp -f kernel/resource-${VENDOR_TMP}.img ${V_RELEASE_DIR}
                            cp -f rockdev/Image/boot.img            ${V_RELEASE_DIR}/boot-${VENDOR_TMP}.img
						'''
					}
				}
			}
	    }
		stage('release'){
			if (params.RELEASE_TO_GITHUB){
				String changeNote = ""
				for(def change : currentBuild.changeSets){
					def entries = change.items
				    for (int i = 0; i < entries.length; i++) {
				        def entry = entries[i]
				        if(entry.getMsg().contains("### RELEASE_NOTE")){
							changeNote += "${entry.getMsg()}"
				        }
				    }
				}
				env.V_CHANGE = changeNote
				sh '''#!/bin/bash
					set -xe
	                shopt -s nullglob
					repo manifest -r -o manifest.xml

					tag=`cat github-tag`

	                github-release release \
	                  --target "${V_REPO_BRANCH}" \
	                  --tag "${tag}" \
	                  --name "${tag}" \
	                  --description "${V_CHANGE}" \
	                  --draft
	                github-release upload \
	                  --tag "${tag}" \
	                  --name "manifest" \
	                  --file "manifest.xml"

	                github-release upload \
	                  --tag "${tag}" \
	                  --name "md5sum" \
	                  --file "$V_RELEASE_DIR/md5"

					for file in $V_RELEASE_DIR/*.zip; do
		                github-release upload \
		                    --tag "${tag}" \
		                    --name "$(basename "$file")" \
		                    --file "$file" &
	              	done
	              	wait
	                github-release edit \
	                  --tag "${tag}" \
	                  --name "${tag}" \
	                  --description "${V_CHANGE}"

	                cp -f rockdev/Image/idbloader.img $V_RELEASE_DIR
				    cp -f rockdev/Image/parameter.txt $V_RELEASE_DIR
				    cp -f rockdev/Image/kernel.img    $V_RELEASE_DIR
				    cp -f rockdev/Image/uboot.img     $V_RELEASE_DIR
				    cp -f rockdev/Image/trust.img     $V_RELEASE_DIR
				'''
			}

			script {
                archiveArtifacts env.V_RELEASE_DIR + '/*.img'
                archiveArtifacts env.V_RELEASE_DIR + '/*.txt'
                currentBuild.description = env.V_RELEASE_TIME
	    	}
		}
	}
}