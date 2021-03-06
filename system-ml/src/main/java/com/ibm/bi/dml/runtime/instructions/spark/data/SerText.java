/**
 * (C) Copyright IBM Corp. 2010, 2015
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * 
 */

package com.ibm.bi.dml.runtime.instructions.spark.data;

import java.io.Serializable;

import org.apache.hadoop.io.Text;

/**
 * Wrapper for Text in order to make it serializable as required for
 * shuffle in spark instructions.
 * 
 */
public class SerText extends Text implements Serializable
{
	private static final long serialVersionUID = -4918278004334054414L;
	
	public SerText(String in) {
		super(in);
	}
}
