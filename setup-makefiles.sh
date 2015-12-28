#!/bin/bash

vendor=huawei
device=angler
outdir=$ANDROID_BUILD_TOP/vendor/$vendor/$device
outdirlite=`echo $outdir | sed "s/$(echo $ANDROID_BUILD_TOP | sed 's/\//\\\\\//g')//g" | sed 's/^\///g'`
makefile=$outdir/$device-vendor-blobs.mk
vendor_makefile=$outdir/device-vendor.mk
year=`date +"%Y"`

self_dir="$(dirname $(readlink -f $0))"
proprietary_files=$self_dir/proprietary-blobs.txt

should_presign()
{
  case $1 in
ims|\
CNEService|\
TimeService|\
DMAgent|\
HWMMITest|\
HwSarControlService|\
Tycho|\
CallStatistics|\
ConnMO|\
DCMO|\
DiagMon|\
DMService|\
GCS|\
HiddenMenu|\
SprintDM) return 0;;
*) return 1;;
  esac
}

mkdir -p $outdir

(cat << EOF) > $makefile
# Copyright (C) $year The CyanogenMod Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# This file is generated by device/$vendor/$device/setup-makefiles.sh

PRODUCT_COPY_FILES += \\
EOF

bloblist=""
lineend=" \\"
count=`wc -l $proprietary_files| awk {'print $1'}`
dism=`egrep -c '(^#|^$)' $proprietary_files`
count=`expr $count - $dism`
for file in `egrep -v '(^#|^$)' $proprietary_files`; do
  count=`expr $count - 1`
  if [ $count = "0" ]; then
    lineend=""
  fi
  # Split the file from the destination (format is "file[:destination]")
  oldifs=$IFS IFS=":" parsing_array=($file) IFS=$oldifs

  file=${parsing_array[0]}
  fileflag=""
  if [[ "$file" =~ ^- ]]; then
      fileflag="-"
      file=$(echo $file | sed -e "s/^-//g")
  fi
  dest=${parsing_array[1]}
  if [ -n "$dest" ]; then
    file=$dest
  fi
  file=$(echo "$file" | sed 's|^system/||')
  if [ -z "$fileflag" ]; then
    echo "    $outdirlite/proprietary/$file:system/$file$lineend" >> $makefile
  fi
  blobllist=$(echo "$blobllist"; echo "$fileflag$file")
done

# for debug
#for i in $(echo $blobllist); do echo "blob=$i"; done
#exit 0

(cat << EOF) > $vendor_makefile
# Copyright (C) $year The CyanogenMod Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# This file is generated by device/$vendor/$device/setup-makefiles.sh

\$(call inherit-product, vendor/$vendor/$device/$device-vendor-blobs.mk)

EOF

(cat << EOF) > $outdir/BoardConfigVendor.mk
# Copyright (C) $year The CyanogenMod Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# This file is generated by device/$vendor/$device/setup-makefiles.sh

EOF

if [ -d $outdir/proprietary/app ]; then
(cat << EOF) > $outdir/proprietary/app/Android.mk
# Copyright (C) $year The CyanogenMod Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# This file is generated by device/$vendor/$device/setup-makefiles.sh

LOCAL_PATH := \$(call my-dir)

EOF

echo "ifeq (\$(TARGET_DEVICE),$device)" >> $outdir/proprietary/app/Android.mk
echo ""  >> $outdir/proprietary/app/Android.mk
echo "# Prebuilt APKs" >> $vendor_makefile
echo "PRODUCT_PACKAGES += \\" >> $vendor_makefile

lineend=" \\"
count=`ls -1 $outdir/proprietary/app/*/*.apk | wc -l`
for apk in `ls $outdir/proprietary/app/*/*apk`; do
  count=`expr $count - 1`
  if [ $count = "0" ]; then
    lineend=""
  fi
    apkname=`basename $apk`
    apkmodulename=`echo $apkname|sed -e 's/\.apk$//gi'`
  if should_presign $apkmodulename; then
    signature="PRESIGNED"
  else
    signature="platform"
  fi
    (cat << EOF) >> $outdir/proprietary/app/Android.mk
include \$(CLEAR_VARS)
LOCAL_MODULE := $apkmodulename
LOCAL_MODULE_TAGS := optional
LOCAL_SRC_FILES := $apkmodulename/$apkname
LOCAL_CERTIFICATE := $signature
LOCAL_MODULE_CLASS := APPS
LOCAL_MODULE_SUFFIX := \$(COMMON_ANDROID_PACKAGE_SUFFIX)
include \$(BUILD_PREBUILT)

EOF

echo "    $apkmodulename$lineend" >> $vendor_makefile
done
echo "" >> $vendor_makefile
echo "endif" >> $outdir/proprietary/app/Android.mk
fi

if [ -d $outdir/proprietary/framework ]; then
(cat << EOF) > $outdir/proprietary/framework/Android.mk
# Copyright (C) $year The CyanogenMod Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# This file is generated by device/$vendor/$device/setup-makefiles.sh

LOCAL_PATH := \$(call my-dir)

EOF

echo "ifeq (\$(TARGET_DEVICE),$device)" >> $outdir/proprietary/framework/Android.mk
echo ""  >> $outdir/proprietary/framework/Android.mk
echo "# Prebuilt jars" >> $vendor_makefile
echo "PRODUCT_PACKAGES += \\" >> $vendor_makefile

lineend=" \\"
count=`ls -1 $outdir/proprietary/framework/*.jar | wc -l`
for JAR in `ls $outdir/proprietary/framework/*jar`; do
  count=`expr $count - 1`
  if [ $count = "0" ]; then
    lineend=""
  fi
    jarname=`basename $JAR`
    jarmodulename=`echo $jarname|sed -e 's/\.jar$//gi'`
    (cat << EOF) >> $outdir/proprietary/framework/Android.mk
include \$(CLEAR_VARS)
LOCAL_MODULE := $jarmodulename
LOCAL_MODULE_TAGS := optional
LOCAL_SRC_FILES := $jarname
LOCAL_CERTIFICATE := PRESIGNED
LOCAL_MODULE_CLASS := JAVA_LIBRARIES
LOCAL_MODULE_SUFFIX := \$(COMMON_JAVA_PACKAGE_SUFFIX)
include \$(BUILD_PREBUILT)

EOF

echo "    $jarmodulename$lineend" >> $vendor_makefile
done
echo "" >> $vendor_makefile
echo "endif" >> $outdir/proprietary/framework/Android.mk
fi

if [ -d $outdir/proprietary/priv-app ]; then
(cat << EOF) > $outdir/proprietary/priv-app/Android.mk
# Copyright (C) $year The CyanogenMod Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# This file is generated by device/$vendor/$device/setup-makefiles.sh

LOCAL_PATH := \$(call my-dir)

EOF

echo "ifeq (\$(TARGET_DEVICE),$device)" >> $outdir/proprietary/priv-app/Android.mk
echo ""  >> $outdir/proprietary/priv-app/Android.mk
echo "# Prebuilt privileged APKs" >> $vendor_makefile
echo "PRODUCT_PACKAGES += \\" >> $vendor_makefile

lineend=" \\"
count=`ls -1 $outdir/proprietary/priv-app/*/*.apk | wc -l`
for privapk in `ls $outdir/proprietary/priv-app/*/*apk`; do
  count=`expr $count - 1`
  if [ $count = "0" ]; then
    lineend=""
  fi
    privapkname=`basename $privapk`
    privmodulename=`echo $privapkname|sed -e 's/\.apk$//gi'`
  if should_presign $privmodulename; then
    signature="PRESIGNED"
  else
    signature="platform"
  fi
    (cat << EOF) >> $outdir/proprietary/priv-app/Android.mk
include \$(CLEAR_VARS)
LOCAL_MODULE := $privmodulename
LOCAL_MODULE_TAGS := optional
LOCAL_SRC_FILES := $privmodulename/$privapkname
LOCAL_CERTIFICATE := $signature
LOCAL_MODULE_CLASS := APPS
LOCAL_PRIVILEGED_MODULE := true
LOCAL_MODULE_SUFFIX := \$(COMMON_ANDROID_PACKAGE_SUFFIX)
include \$(BUILD_PREBUILT)

EOF

echo "    $privmodulename$lineend" >> $vendor_makefile
done
echo "" >> $vendor_makefile
echo "endif" >> $outdir/proprietary/priv-app/Android.mk
fi

libs=`echo "$bloblist" | grep '\-lib' | cut -d'-' -f2 | head -1`

if [ -f $outdir/proprietary/$libs ]; then
(cat << EOF) > $outdir/proprietary/lib/Android.mk
# Copyright (C) $year The CyanogenMod Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# This file is generated by device/$vendor/$device/setup-makefiles.sh

LOCAL_PATH := \$(call my-dir)

EOF

echo "ifeq (\$(TARGET_DEVICE),$device)" >> $outdir/proprietary/lib/Android.mk
echo ""  >> $outdir/proprietary/lib/Android.mk
echo "# Prebuilt libs needed for compilation" >> $vendor_makefile
echo "PRODUCT_PACKAGES += \\" >> $vendor_makefile

lineend=" \\"
count=`echo "$blobllist" | grep '^-.*/lib/' | wc -l`
for lib in `echo "$blobllist" | grep '^-.*/lib/' | cut -d'/' -f2`;do
  count=`expr $count - 1`
  if [ $count = "0" ]; then
    lineend=""
  fi
    libname=`basename $lib`
    libmodulename=`echo $libname|sed -e 's/\.so$//gi'`
    (cat << EOF) >> $outdir/proprietary/lib/Android.mk
include \$(CLEAR_VARS)
LOCAL_MODULE := $libmodulename
LOCAL_MODULE_OWNER := $VENDOR
LOCAL_MODULE_TAGS := optional
LOCAL_SRC_FILES := $libname
LOCAL_MODULE_PATH := \$(TARGET_OUT_SHARED_LIBRARIES)
LOCAL_MODULE_SUFFIX := .so
LOCAL_MODULE_CLASS := SHARED_LIBRARIES
include \$(BUILD_PREBUILT)

EOF

echo "    $libmodulename$lineend" >> $vendor_makefile
done
echo "" >> $vendor_makefile
echo "endif" >> $outdir/proprietary/lib/Android.mk
fi
