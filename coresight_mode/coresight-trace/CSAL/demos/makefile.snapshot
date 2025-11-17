#############################################################################
#  CoreSight Access Library
#
#  Copyright (C) ARM Limited, 2017. All rights reserved.
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at#
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#
#############################################################################
#
# Makefile to collect all files for a snapshot archive into DS-5
# Copied from ./demos/Makefile.snapshot to ./bin/.../Makefile when demos built

# create a snapshot file 
cstrace.tar: snapshot.ini cstrace.bin kernel_dump.bin trace.ini
	tar cvf $@ $^ cpu_*.ini device_*.ini
