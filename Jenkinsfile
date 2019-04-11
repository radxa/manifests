import java.text.SimpleDateFormat
//#################################

def repoSync(fullClean, fullReset, manifestRepo, manifestRev, manifestPath){
    checkout changelog: true, poll: false, scm: [$class: 'RepoScm', currentBranch: true, \
        forceSync: true, jobs: 4, manifestBranch: manifestRev, \
        manifestFile: manifestPath, manifestRepositoryUrl: manifestRepo, \
        quiet: false, resetFirst: fullClean, resetFirst: fullReset]
} 
//#################################

node('jolin') {
	stage('Environment'){
		def dateFormat = new SimpleDateFormat("yyyyMMdd_HHmm")
        def date = new Date()

        env.ROCKS_RELEASE_TIME = dateFormat.format(date)
        env.ROCKS_RELEASE_DIR = "release"
        env.ROCKS_VENDOR = "rockpi-4b"
        env.ROCKS_LUNCH = "rk3399_box"
        env.PATH = "/sbin:" + env.PATH

		dir('build-environment') {
			checkout scm
		}
	}

 	def uid = sh (returnStdout: true, script: 'id -u').trim()
    def gid = sh (returnStdout: true, script: 'id -g').trim()
    def environment = docker.build('android-builder:9.x', "--build-arg USER_ID=${uid} --build-arg GROUP_ID=${gid} build-environment")

    environment.inside {
		stage('repo') {
		    repoSync(true, true, "https://github.com/radxa/manifests.git", "rockpi-box-9.0", "rockpi-release.xml")
		}
	    stage('uboot'){
	    	sh '''#!/bin/bash
	    		#uboot
				cd u-boot
				make distclean
				make mrproper
				./make.sh rk3399
				cd -
	    	'''
	    }
	    stage('kernel'){
	    	sh '''#!/bin/bash
	    		# kernel
				cd kernel
				make distclean
				for hardware in $ROCKS_VENDOR;
				do
				    echo "###################kernel build $hardware###################"
				    make ARCH=arm64 rockchip_defconfig
				    make rk3399-$hardware.img -j4
				    cp resource.img $hardware.img
				done
				cd -
	    	'''
	    }
		stage('android') {
			if (params.FULL_CLEAN_ANDROID){
		        sh '''
		            rm -rf out/target/product
		        '''
		    }else{
		    	sh '''
		            rm -rf out/target/product/${ROCKS_LUNCH}/root
		            rm -rf out/target/product/${ROCKS_LUNCH}/system
		            rm -rf out/target/product/${ROCKS_LUNCH}/recovery
		        '''
		    }
			sh '''#!/bin/bash
				
				# make android
				. build/envsetup.sh
				lunch "$ROCKS_LUNCH"-userdebug
				make -j8

			'''
		}
		stage('make image') {
			sh '''#!/bin/bash
				 . build/envsetup.sh
				lunch "$ROCKS_LUNCH"-userdebug

				# make rk image
				ln -s -f RKTools/linux/Linux_Pack_Firmware/rockdev/ rockdev
				
				rm -rf $ROCKS_RELEASE_DIR
				mkdir -p $ROCKS_RELEASE_DIR
				
				for hardware in $ROCKS_VENDOR;
				do
				    cp -f kernel/$hardware.img kernel/resource.img
				    ./mkimage.sh
				    
				    # make update image
				    cd rockdev
				    rm -f Image
				    ln -s -f Image-$ROCKS_LUNCH Image
				    ./mkupdate.sh
				    # make gpt image
				    ./android-gpt.sh
				    cd -
				    
				    # release image
				    commitId=`git -C .repo/manifests rev-parse --short HEAD`
				    #typeset -u hardware_up
				    hardware_up="$hardware"
				    release_name="${hardware_up}-pie-${ROCKS_RELEASE_TIME}_${commitId}"
				    
				    mv rockdev/update.img    $ROCKS_RELEASE_DIR/${release_name}-rkupdate.img
				    mv rockdev/Image/gpt.img $ROCKS_RELEASE_DIR/${release_name}-gpt.img
				    
				    cd $ROCKS_RELEASE_DIR
				    md5sum ${release_name}-rkupdate.img >> md5
				    md5sum ${release_name}-gpt.img >> md5
				    
				    zip ${release_name}-rkupdate.zip ${release_name}-rkupdate.img
				    zip ${release_name}-gpt.zip ${release_name}-gpt.img
				    rm -f *.img
				    cd -

				    cp -f rockdev/Image/resource.img  $ROCKS_RELEASE_DIR/resource_$hardware.img
				    cp -f rockdev/Image/idbloader.img $ROCKS_RELEASE_DIR
				    cp -f rockdev/Image/parameter.txt $ROCKS_RELEASE_DIR
				    cp -f rockdev/Image/kernel.img    $ROCKS_RELEASE_DIR
				    cp -f rockdev/Image/boot.img      $ROCKS_RELEASE_DIR
				    cp -f rockdev/Image/uboot.img     $ROCKS_RELEASE_DIR
				    cp -f rockdev/Image/trust.img     $ROCKS_RELEASE_DIR
				done
			'''
		}
		stage('release'){
			if (params.RELEASE_TO_GITHUB){
				String changeNote = ""
				if(currentBuild.changeSets != null && currentBuild.changeSets.size() >= 1){
					def github = currentBuild.changeSets[0]
					def entries = github.items
				    for (int i = 0; i < entries.length; i++) {
				        def entry = entries[i]
				        if(entry.comment.contains("### RELEASE_NOTE")){
							changeNote += "${entry.comment}"
				        }
				    }
				}
				env.ROCKS_CHANGE = changeNote
				sh '''#!/bin/bash
					set -xe
	                shopt -s nullglob
					commitId=`git -C .repo/manifests rev-parse --short HEAD`
					repo manifest -r -o manifest.xml

					tag=Android9.0_${ROCKS_LUNCH}_${ROCKS_RELEASE_TIME}_${commitId}

	                github-release release \
	                  --target "rockpi-box-9.0" \
	                  --tag "${tag}" \
	                  --name "${tag}" \
	                  --description "${ROCKS_CHANGE}" \
	                  --draft
	                github-release upload \
	                  --tag "${tag}" \
	                  --name "manifest" \
	                  --file "manifest.xml"

	                github-release upload \
	                  --tag "${tag}" \
	                  --name "md5sum" \
	                  --file "$ROCKS_RELEASE_DIR/md5"

					for file in $ROCKS_RELEASE_DIR/*.zip; do
		                github-release upload \
		                    --tag "${tag}" \
		                    --name "$(basename "$file")" \
		                    --file "$file" &
	              	done
	              	wait
	                github-release edit \
	                  --tag "${tag}" \
	                  --name "${tag}" \
	                  --description "${ROCKS_CHANGE}"
				'''
				script {
			        archiveArtifacts env.ROCKS_RELEASE_DIR + '/*.img'
	    		}
			}

			script {
		        currentBuild.description = env.ROCKS_RELEASE_TIME
	    	}
		}
    }
}