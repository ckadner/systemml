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

package com.ibm.bi.dml.runtime.instructions;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

import com.ibm.bi.dml.api.monitoring.Location;
import com.ibm.bi.dml.lops.Lop;
import com.ibm.bi.dml.parser.DataIdentifier;
import com.ibm.bi.dml.runtime.DMLRuntimeException;
import com.ibm.bi.dml.runtime.DMLUnsupportedOperationException;
import com.ibm.bi.dml.runtime.controlprogram.context.ExecutionContext;


public abstract class Instruction 
{
	public enum INSTRUCTION_TYPE { 
		CONTROL_PROGRAM, 
		MAPREDUCE, 
		EXTERNAL_LIBRARY, 
		MAPREDUCE_JOB, 
		BREAKPOINT, 
		SPARK 
	};
	
	protected static final Log LOG = LogFactory.getLog(Instruction.class.getName());
	
	public static final String OPERAND_DELIM = Lop.OPERAND_DELIMITOR;
	public static final String DATATYPE_PREFIX = Lop.DATATYPE_PREFIX;
	public static final String VALUETYPE_PREFIX = Lop.VALUETYPE_PREFIX;
	public static final String LITERAL_PREFIX = Lop.LITERAL_PREFIX;
	public static final String INSTRUCTION_DELIM = Lop.INSTRUCTION_DELIMITOR;
	public static final String NAME_VALUE_SEPARATOR = Lop.NAME_VALUE_SEPARATOR;
	public static final String SP_INST_PREFIX = "sp_";
	
	//basic instruction meta data
	protected INSTRUCTION_TYPE type = null;
	protected String instString = null;
	protected String instOpcode = null;
	private long instID = -1;
	
	//originating script positions
	protected int beginLine = -1;
	protected int endLine = -1;  
	protected int beginCol = -1; 
	protected int endCol = -1;
	
	public void setType (INSTRUCTION_TYPE tp ) {
		type = tp;
	}
	
	public INSTRUCTION_TYPE getType() {
		return type;
	}
	
	/**
	 * Setter for instruction line number 
	 * @param ln Exact (or approximate) DML script line number
	 */
	public void setLocation ( int beginLine, int endLine,  int beginCol, int endCol) {
		this.beginLine = beginLine;
		this.endLine = endLine;
		this.beginCol = beginCol;
		this.endCol = endCol;
	}
	
	public void setLocation(Lop lop) {
		if(lop != null) {
			this.beginLine = lop._beginLine;
			this.endLine = lop._endLine;
			this.beginCol = lop._beginColumn;
			this.endCol = lop._endColumn;
		}
	}
	
	public void setLocation(DataIdentifier id) {
		if(id != null) {
			this.beginLine = id.getBeginLine();
			this.endLine = id.getEndLine();
			this.beginCol = id.getBeginColumn();
			this.endCol = id.getEndColumn();
		}
	}
	
	public void setLocation(Instruction oldInst) {
		if(oldInst != null) {
			this.beginLine = oldInst.beginLine;
			this.endLine = oldInst.endLine;
			this.beginCol = oldInst.beginCol;
			this.endCol = oldInst.endCol;
		}
	}
	
	public Location getLocation() {
		// Rather than exposing 4 different getter methods. Also Location doesnot contain any references to Spark libraries
		if(beginLine == -1 || endLine == -1 || beginCol == -1 || endCol == -1) {
			return null;
		}
		else
			return new Location(beginLine, endLine, beginCol, endCol);
	}
	
	
	/**
	 * Getter for instruction line number
	 * @return lineNum Instruction approximate DML script line number
	 */
	public int getLineNum() {
		return beginLine;
	}

	/**
	 * Setter for instruction unique identifier 
	 * @param id Instruction unique identifier
	 */
	public void setInstID ( long id ) {
		instID = id;
	}
		
	/**
	 * Getter for instruction unique identifier
	 * @return instID Instruction unique identifier
	 */
	public long getInstID() {
		return instID;
	}

	public void printMe() {
		LOG.debug(instString);
	}
	
	public String toString() {
		return instString;
	}
	
	public String getGraphString() {
		return null;
	}

	public String getOpcode() {
		return instOpcode;
	}
	
	public String getExtendedOpcode() {
		if( type == INSTRUCTION_TYPE.SPARK )
			return SP_INST_PREFIX + getOpcode();
		else
			return getOpcode();
	}
	
	/**
	 * 
	 * @return
	 */
	public boolean requiresLabelUpdate()
	{
		return instString.contains( Lop.VARIABLE_NAME_PLACEHOLDER );
	}	
	
	/**
	 * All instructions that have thread-specific filenames or names encoded in it
	 * should overwrite this method in order to update (1) the in-memory instruction
	 * and (2) the instruction string 
	 * 
	 * @param pattern
	 * @param replace
	 * @throws DMLRuntimeException 
	 */
	public void updateInstructionThreadID(String pattern, String replace) 
		throws DMLRuntimeException
	{
		//do nothing
	}
	
	/**
	 * This method should be used for any setup before executing this instruction.
	 * Overwriting methods should first call the super method and subsequently do
	 * their custom setup.
	 * 
	 * @param ec
	 * @return
	 * @throws DMLRuntimeException
	 * @throws DMLUnsupportedOperationException 
	 */
	public Instruction preprocessInstruction(ExecutionContext ec)
		throws DMLRuntimeException, DMLUnsupportedOperationException
	{
		//update debug status
		ec.updateDebugState( this );
		
		//return instruction ifself
		return this;
	}
	
	/**
	 * This method should be used to execute the instruction. 
	 * 
	 * @param ec
	 * @throws DMLRuntimeException
	 * @throws DMLUnsupportedOperationException
	 */
	public abstract void processInstruction(ExecutionContext ec) 
		throws DMLRuntimeException, DMLUnsupportedOperationException;
	
	/**
	 * This method should be used for any tear down after executing this instruction.
	 * Overwriting methods should first do their custom tear down and subsequently 
	 * call the super method.
	 * 
	 * @param ec
	 */
	public void postprocessInstruction(ExecutionContext ec)
		throws DMLRuntimeException
	{
		//do nothing
	}
}
