/**
 * IBM Confidential
 * OCO Source Materials
 * (C) Copyright IBM Corp. 2010, 2014
 * The source code for this program is not published or otherwise divested of its trade secrets, irrespective of what has been deposited with the U.S. Copyright Office.
 */

package com.ibm.bi.dml.antlr4;

import java.io.File;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Vector;

import org.antlr.v4.runtime.ParserRuleContext;
import org.antlr.v4.runtime.Token;
import org.antlr.v4.runtime.tree.ErrorNode;
import org.antlr.v4.runtime.tree.TerminalNode;

import com.ibm.bi.dml.antlr4.DmlParser.AddSubExpressionContext;
import com.ibm.bi.dml.antlr4.DmlParser.AssignmentStatementContext;
import com.ibm.bi.dml.antlr4.DmlParser.AtomicExpressionContext;
import com.ibm.bi.dml.antlr4.DmlParser.BooleanAndExpressionContext;
import com.ibm.bi.dml.antlr4.DmlParser.BooleanNotExpressionContext;
import com.ibm.bi.dml.antlr4.DmlParser.BooleanOrExpressionContext;
import com.ibm.bi.dml.antlr4.DmlParser.BuiltinFunctionExpressionContext;
import com.ibm.bi.dml.antlr4.DmlParser.CommandlineParamExpressionContext;
import com.ibm.bi.dml.antlr4.DmlParser.CommandlinePositionExpressionContext;
import com.ibm.bi.dml.antlr4.DmlParser.ConstDoubleIdExpressionContext;
import com.ibm.bi.dml.antlr4.DmlParser.ConstFalseExpressionContext;
import com.ibm.bi.dml.antlr4.DmlParser.ConstIntIdExpressionContext;
import com.ibm.bi.dml.antlr4.DmlParser.ConstStringIdExpressionContext;
import com.ibm.bi.dml.antlr4.DmlParser.ConstTrueExpressionContext;
import com.ibm.bi.dml.antlr4.DmlParser.DataIdExpressionContext;
import com.ibm.bi.dml.antlr4.DmlParser.DataIdentifierContext;
import com.ibm.bi.dml.antlr4.DmlParser.DmlprogramContext;
import com.ibm.bi.dml.antlr4.DmlParser.ExpressionContext;
import com.ibm.bi.dml.antlr4.DmlParser.ExternalFunctionDefExpressionContext;
import com.ibm.bi.dml.antlr4.DmlParser.ForStatementContext;
import com.ibm.bi.dml.antlr4.DmlParser.FunctionCallAssignmentStatementContext;
import com.ibm.bi.dml.antlr4.DmlParser.FunctionCallMultiAssignmentStatementContext;
import com.ibm.bi.dml.antlr4.DmlParser.FunctionStatementContext;
import com.ibm.bi.dml.antlr4.DmlParser.IfStatementContext;
import com.ibm.bi.dml.antlr4.DmlParser.IfdefAssignmentStatementContext;
import com.ibm.bi.dml.antlr4.DmlParser.ImportStatementContext;
import com.ibm.bi.dml.antlr4.DmlParser.IndexedExpressionContext;
import com.ibm.bi.dml.antlr4.DmlParser.InternalFunctionDefExpressionContext;
import com.ibm.bi.dml.antlr4.DmlParser.IterablePredicateColonExpressionContext;
import com.ibm.bi.dml.antlr4.DmlParser.IterablePredicateSeqExpressionContext;
import com.ibm.bi.dml.antlr4.DmlParser.MatrixDataTypeCheckContext;
import com.ibm.bi.dml.antlr4.DmlParser.MatrixMulExpressionContext;
import com.ibm.bi.dml.antlr4.DmlParser.Ml_typeContext;
import com.ibm.bi.dml.antlr4.DmlParser.ModIntDivExpressionContext;
import com.ibm.bi.dml.antlr4.DmlParser.MultDivExpressionContext;
import com.ibm.bi.dml.antlr4.DmlParser.ParForStatementContext;
import com.ibm.bi.dml.antlr4.DmlParser.ParameterizedExpressionContext;
import com.ibm.bi.dml.antlr4.DmlParser.PathStatementContext;
import com.ibm.bi.dml.antlr4.DmlParser.PowerExpressionContext;
import com.ibm.bi.dml.antlr4.DmlParser.RelationalExpressionContext;
import com.ibm.bi.dml.antlr4.DmlParser.SimpleDataIdentifierExpressionContext;
import com.ibm.bi.dml.antlr4.DmlParser.StatementContext;
import com.ibm.bi.dml.antlr4.DmlParser.StrictParameterizedExpressionContext;
import com.ibm.bi.dml.antlr4.DmlParser.StrictParameterizedKeyValueStringContext;
import com.ibm.bi.dml.antlr4.DmlParser.TypedArgNoAssignContext;
import com.ibm.bi.dml.antlr4.DmlParser.UnaryExpressionContext;
import com.ibm.bi.dml.antlr4.DmlParser.ValueTypeContext;
import com.ibm.bi.dml.antlr4.DmlParser.WhileStatementContext;
import com.ibm.bi.dml.parser.ConditionalPredicate;
import com.ibm.bi.dml.parser.DMLProgram;
import com.ibm.bi.dml.parser.DataIdentifier;
import com.ibm.bi.dml.parser.DoubleIdentifier;
import com.ibm.bi.dml.parser.Expression;
import com.ibm.bi.dml.parser.Expression.DataOp;
import com.ibm.bi.dml.parser.Expression.DataType;
import com.ibm.bi.dml.parser.Expression.ValueType;
import com.ibm.bi.dml.parser.DataExpression;
import com.ibm.bi.dml.parser.ForStatement;
import com.ibm.bi.dml.parser.FunctionCallIdentifier;
import com.ibm.bi.dml.parser.IfStatement;
import com.ibm.bi.dml.parser.ImportStatement;
import com.ibm.bi.dml.parser.IndexedIdentifier;
import com.ibm.bi.dml.parser.IntIdentifier;
import com.ibm.bi.dml.parser.IterablePredicate;
import com.ibm.bi.dml.parser.LanguageException;
import com.ibm.bi.dml.parser.ParseException;
import com.ibm.bi.dml.parser.PathStatement;
import com.ibm.bi.dml.parser.StatementBlock;

public class DmlSyntacticValidator implements DmlListener {
	@SuppressWarnings("unused")
	private static final String _COPYRIGHT = "Licensed Materials - Property of IBM\n(C) Copyright IBM Corp. 2010, 2014\n" +
                                             "US Government Users Restricted Rights - Use, duplication  disclosure restricted by GSA ADP Schedule Contract with IBM Corp.";
	
	// Functions we have to implement but don't really need it
	@Override
	public void enterAddSubExpression(AddSubExpressionContext ctx) { }
	@Override
	public void enterAssignmentStatement(AssignmentStatementContext ctx) {}
	@Override
	public void enterAtomicExpression(AtomicExpressionContext ctx) { }
	@Override
	public void enterBooleanAndExpression(BooleanAndExpressionContext ctx) { }
	@Override
	public void enterBooleanNotExpression(BooleanNotExpressionContext ctx) { }
	@Override
	public void enterBooleanOrExpression(BooleanOrExpressionContext ctx) { }
	@Override
	public void enterCommandlineParamExpression(CommandlineParamExpressionContext ctx) { }
	@Override
	public void enterCommandlinePositionExpression(CommandlinePositionExpressionContext ctx) { }	
	@Override
	public void enterConstDoubleIdExpression(ConstDoubleIdExpressionContext ctx) { }
	@Override
	public void enterConstIntIdExpression(ConstIntIdExpressionContext ctx) { }
	@Override
	public void enterConstStringIdExpression(ConstStringIdExpressionContext ctx) { }
	@Override
	public void enterDataIdExpression(DataIdExpressionContext ctx) { }

	@Override
	public void enterDmlprogram(DmlprogramContext ctx) { }
	@Override
	public void enterEveryRule(ParserRuleContext arg0) {
		if(arg0 instanceof StatementContext) {
			if(((StatementContext) arg0).info == null) {
				((StatementContext) arg0).info = new StatementInfo();
			}
		}
		if(arg0 instanceof FunctionStatementContext) {
			if(((FunctionStatementContext) arg0).info == null) {
				((FunctionStatementContext) arg0).info = new StatementInfo();
			}
		}
		if(arg0 instanceof ExpressionContext) {
			if(((ExpressionContext) arg0).info == null) {
				((ExpressionContext) arg0).info = new ExpressionInfo();
			}
		}
		if(arg0 instanceof DataIdentifierContext) {
			if(((DataIdentifierContext) arg0).dataInfo == null) {
				((DataIdentifierContext) arg0).dataInfo = new ExpressionInfo();
			}
		}
	}
	@Override
	public void enterExternalFunctionDefExpression(ExternalFunctionDefExpressionContext ctx) { }
	@Override
	public void enterForStatement(ForStatementContext ctx) {}
	@Override
	public void enterFunctionCallAssignmentStatement(FunctionCallAssignmentStatementContext ctx) { }
	@Override
	public void enterFunctionCallMultiAssignmentStatement(FunctionCallMultiAssignmentStatementContext ctx) { }
	@Override
	public void enterIfStatement(IfStatementContext ctx) { }
	@Override
	public void enterImportStatement(ImportStatementContext ctx) { }
	@Override
	public void enterIndexedExpression(IndexedExpressionContext ctx) { }
	@Override
	public void enterInternalFunctionDefExpression(InternalFunctionDefExpressionContext ctx) { }
	public void enterMatrixMulExpression(MatrixMulExpressionContext ctx) { }
	@Override
	public void enterMl_type(Ml_typeContext ctx) { }
	@Override
	public void enterModIntDivExpression(ModIntDivExpressionContext ctx) { }
	@Override
	public void enterMultDivExpression(MultDivExpressionContext ctx) { }
	@Override
	public void enterParameterizedExpression(ParameterizedExpressionContext ctx) { }
	@Override
	public void enterParForStatement(ParForStatementContext ctx) { }
	@Override
	public void enterPathStatement(PathStatementContext ctx) { }
	@Override
	public void enterPowerExpression(PowerExpressionContext ctx) { }
	@Override
	public void enterRelationalExpression(RelationalExpressionContext ctx) { }
	@Override
	public void enterSimpleDataIdentifierExpression(SimpleDataIdentifierExpressionContext ctx) { }
	@Override
	public void enterStrictParameterizedExpression(StrictParameterizedExpressionContext ctx) { }
	@Override
	public void enterTypedArgNoAssign(TypedArgNoAssignContext ctx) { }
	@Override
	public void enterUnaryExpression(UnaryExpressionContext ctx) { }
	@Override
	public void enterValueType(ValueTypeContext ctx) { }
	@Override
	public void enterWhileStatement(WhileStatementContext ctx) { }
	
	@Override
	public void visitErrorNode(ErrorNode arg0) { }
	@Override
	public void visitTerminal(TerminalNode arg0) { }
	@Override
	public void exitEveryRule(ParserRuleContext arg0) {}
	// --------------------------------------------------------------------
	private void setFileLineColumn(Expression expr, ParserRuleContext ctx) {
		expr.setFilename(DmlSyntacticErrorListener.currentFileName.peek());
		expr.setBeginLine(ctx.start.getLine());
		expr.setBeginColumn(ctx.start.getCharPositionInLine());
		expr.setEndLine(ctx.stop.getLine());
		expr.setEndColumn(ctx.stop.getCharPositionInLine());
	}
	
	private void setFileLineColumn(com.ibm.bi.dml.parser.Statement stmt, ParserRuleContext ctx) {
		stmt.setFilename(DmlSyntacticErrorListener.currentFileName.peek());
		stmt.setBeginLine(ctx.start.getLine());
		stmt.setBeginColumn(ctx.start.getCharPositionInLine());
		stmt.setEndLine(ctx.stop.getLine());
		stmt.setEndColumn(ctx.stop.getCharPositionInLine());
	}
	
	// For now do no type checking, let validation handle it.
	// This way parser doesn't have to open metadata file
	@Override
	public void exitAddSubExpression(AddSubExpressionContext ctx) {
		if(ctx.left.info.expr != null && ctx.right.info.expr != null) {
			com.ibm.bi.dml.parser.Expression.BinaryOp bop = com.ibm.bi.dml.parser.Expression.getBinaryOp(ctx.op.getText());
			ctx.info.expr = new com.ibm.bi.dml.parser.BinaryExpression(bop);
			((com.ibm.bi.dml.parser.BinaryExpression)ctx.info.expr).setLeft(ctx.left.info.expr);
			((com.ibm.bi.dml.parser.BinaryExpression)ctx.info.expr).setRight(ctx.right.info.expr);
			setFileLineColumn(ctx.info.expr, ctx);
		}
	}
	@Override
	public void exitModIntDivExpression(ModIntDivExpressionContext ctx) {
		if(ctx.left.info.expr != null && ctx.right.info.expr != null) {
			com.ibm.bi.dml.parser.Expression.BinaryOp bop = com.ibm.bi.dml.parser.Expression.getBinaryOp(ctx.op.getText());
			ctx.info.expr = new com.ibm.bi.dml.parser.BinaryExpression(bop);
			((com.ibm.bi.dml.parser.BinaryExpression)ctx.info.expr).setLeft(ctx.left.info.expr);
			((com.ibm.bi.dml.parser.BinaryExpression)ctx.info.expr).setRight(ctx.right.info.expr);
			setFileLineColumn(ctx.info.expr, ctx);
		}
	}
	
	@Override
	public void exitUnaryExpression(UnaryExpressionContext ctx) {
		if(ctx.left.info.expr != null) {
			String fileName = DmlSyntacticValidatorHelper.getCurrentFileName();
			int line = ctx.start.getLine();
			int col = ctx.start.getCharPositionInLine();
			
			if(ctx.left.info.expr instanceof IntIdentifier) {
				if(ctx.op.getText().compareTo("-") == 0) {
					((IntIdentifier) ctx.left.info.expr).multiplyByMinusOne();
				}
				ctx.info.expr = ctx.left.info.expr;
			}
			else if(ctx.left.info.expr instanceof DoubleIdentifier) {
				if(ctx.op.getText().compareTo("-") == 0) {
					((DoubleIdentifier) ctx.left.info.expr).multiplyByMinusOne();
				}
				ctx.info.expr = ctx.left.info.expr;
			}
			else {
				com.ibm.bi.dml.parser.Expression right = new com.ibm.bi.dml.parser.IntIdentifier(1, fileName, line, col, line, col);
				if(ctx.op.getText().compareTo("-") == 0) {
					right = new com.ibm.bi.dml.parser.IntIdentifier(-1, fileName, line, col, line, col);
				}
				
				com.ibm.bi.dml.parser.Expression.BinaryOp bop = com.ibm.bi.dml.parser.Expression.getBinaryOp("*");
				ctx.info.expr = new com.ibm.bi.dml.parser.BinaryExpression(bop);
				((com.ibm.bi.dml.parser.BinaryExpression)ctx.info.expr).setLeft(ctx.left.info.expr);
				((com.ibm.bi.dml.parser.BinaryExpression)ctx.info.expr).setRight(right);
			}
			setFileLineColumn(ctx.info.expr, ctx);
		}
	}
	
	@Override
	public void exitMultDivExpression(MultDivExpressionContext ctx) {
		com.ibm.bi.dml.parser.Expression.BinaryOp bop = com.ibm.bi.dml.parser.Expression.getBinaryOp(ctx.op.getText());
		ctx.info.expr = new com.ibm.bi.dml.parser.BinaryExpression(bop);
		((com.ibm.bi.dml.parser.BinaryExpression)ctx.info.expr).setLeft(ctx.left.info.expr);
		((com.ibm.bi.dml.parser.BinaryExpression)ctx.info.expr).setRight(ctx.right.info.expr);
		setFileLineColumn(ctx.info.expr, ctx);
	}
	@Override
	public void exitPowerExpression(PowerExpressionContext ctx) {
		com.ibm.bi.dml.parser.Expression.BinaryOp bop = com.ibm.bi.dml.parser.Expression.getBinaryOp(ctx.op.getText());
		ctx.info.expr = new com.ibm.bi.dml.parser.BinaryExpression(bop);
		((com.ibm.bi.dml.parser.BinaryExpression)ctx.info.expr).setLeft(ctx.left.info.expr);
		((com.ibm.bi.dml.parser.BinaryExpression)ctx.info.expr).setRight(ctx.right.info.expr);
		setFileLineColumn(ctx.info.expr, ctx);
	}
	
	@Override
	public void exitMatrixMulExpression(MatrixMulExpressionContext ctx) {
		com.ibm.bi.dml.parser.Expression.BinaryOp bop = com.ibm.bi.dml.parser.Expression.getBinaryOp(ctx.op.getText());
		ctx.info.expr = new com.ibm.bi.dml.parser.BinaryExpression(bop);
		((com.ibm.bi.dml.parser.BinaryExpression)ctx.info.expr).setLeft(ctx.left.info.expr);
		((com.ibm.bi.dml.parser.BinaryExpression)ctx.info.expr).setRight(ctx.right.info.expr);
		setFileLineColumn(ctx.info.expr, ctx);
	}

	// --------------------------------------------------------------------

	@Override
	public void exitRelationalExpression(RelationalExpressionContext ctx) {
		if(ctx.left.info.expr != null && ctx.right.info.expr != null) {
			com.ibm.bi.dml.parser.Expression.RelationalOp rop = com.ibm.bi.dml.parser.Expression.getRelationalOp(ctx.op.getText());
			ctx.info.expr = new com.ibm.bi.dml.parser.RelationalExpression(rop);
			((com.ibm.bi.dml.parser.RelationalExpression)ctx.info.expr).setLeft(ctx.left.info.expr);
			((com.ibm.bi.dml.parser.RelationalExpression)ctx.info.expr).setRight(ctx.right.info.expr);
			setFileLineColumn(ctx.info.expr, ctx);
		}
	}
	
	// --------------------------------------------------------------------
	
	@Override
	public void exitBooleanAndExpression(BooleanAndExpressionContext ctx) {
		if(ctx.left.info.expr != null && ctx.right.info.expr != null) {
			com.ibm.bi.dml.parser.Expression.BooleanOp bop = com.ibm.bi.dml.parser.Expression.getBooleanOp(ctx.op.getText());
			ctx.info.expr = new com.ibm.bi.dml.parser.BooleanExpression(bop);
			((com.ibm.bi.dml.parser.BooleanExpression)ctx.info.expr).setLeft(ctx.left.info.expr);
			((com.ibm.bi.dml.parser.BooleanExpression)ctx.info.expr).setRight(ctx.right.info.expr);
			setFileLineColumn(ctx.info.expr, ctx);
		}
	}
	
	@Override
	public void exitBooleanOrExpression(BooleanOrExpressionContext ctx) {
		if(ctx.left.info.expr != null && ctx.right.info.expr != null) {
			com.ibm.bi.dml.parser.Expression.BooleanOp bop = com.ibm.bi.dml.parser.Expression.getBooleanOp(ctx.op.getText());
			ctx.info.expr = new com.ibm.bi.dml.parser.BooleanExpression(bop);
			((com.ibm.bi.dml.parser.BooleanExpression)ctx.info.expr).setLeft(ctx.left.info.expr);
			((com.ibm.bi.dml.parser.BooleanExpression)ctx.info.expr).setRight(ctx.right.info.expr);
			setFileLineColumn(ctx.info.expr, ctx);
		}
	}

	@Override
	public void exitBooleanNotExpression(BooleanNotExpressionContext ctx) {
		if(ctx.left.info.expr != null) {
			com.ibm.bi.dml.parser.Expression.BooleanOp bop = com.ibm.bi.dml.parser.Expression.getBooleanOp(ctx.op.getText());
			ctx.info.expr = new com.ibm.bi.dml.parser.BooleanExpression(bop);
			((com.ibm.bi.dml.parser.BooleanExpression)ctx.info.expr).setLeft(ctx.left.info.expr);
			setFileLineColumn(ctx.info.expr, ctx);
		}
	}
	
	// --------------------------------------------------------------------
	
	@Override
	public void exitAtomicExpression(AtomicExpressionContext ctx) {
		ctx.info.expr = ctx.left.info.expr;
		setFileLineColumn(ctx.info.expr, ctx);
	}
	
//	@Override
//	public void exitConstBooleanIdExpression(ConstBooleanIdExpressionContext ctx) {
//		boolean val = false;
//		if(ctx.getText().compareTo("TRUE") == 0) {
//			val = true;
//		}
//		else if(ctx.getText().compareTo("FALSE") == 0) {
//			val = false;
//		}
//		else {
//			DmlSyntacticValidatorHelper.notifyErrorListeners("cannot parse the boolean value: \'" +  ctx.getText() + "\'", ctx.getStart());
//			return;
//		}
//		int linePosition = ctx.start.getLine();
//		int charPosition = ctx.start.getCharPositionInLine();
//		ctx.info.expr = new com.ibm.bi.dml.parser.BooleanIdentifier(val, DmlSyntacticErrorListener.currentFileName.peek(), linePosition, charPosition, linePosition, charPosition);
//		setFileLineColumn(ctx.info.expr, ctx);
//	}

	@Override
	public void exitConstDoubleIdExpression(ConstDoubleIdExpressionContext ctx) {
		try {
			double val = Double.parseDouble(ctx.getText());
			int linePosition = ctx.start.getLine();
			int charPosition = ctx.start.getCharPositionInLine();
			ctx.info.expr = new com.ibm.bi.dml.parser.DoubleIdentifier(val, DmlSyntacticErrorListener.currentFileName.peek(), linePosition, charPosition, linePosition, charPosition);
			setFileLineColumn(ctx.info.expr, ctx);
		}
		catch(Exception e) {
			DmlSyntacticValidatorHelper.notifyErrorListeners("cannot parse the double value: \'" +  ctx.getText() + "\'", ctx.getStart());
			return;
		}
	}

	@Override
	public void exitConstIntIdExpression(ConstIntIdExpressionContext ctx) {
		try {
			long val = Long.parseLong(ctx.getText());
			int linePosition = ctx.start.getLine();
			int charPosition = ctx.start.getCharPositionInLine();
			ctx.info.expr = new com.ibm.bi.dml.parser.IntIdentifier(val, DmlSyntacticErrorListener.currentFileName.peek(), linePosition, charPosition, linePosition, charPosition);
			setFileLineColumn(ctx.info.expr, ctx);
		}
		catch(Exception e) {
			DmlSyntacticValidatorHelper.notifyErrorListeners("cannot parse the integer value: \'" +  ctx.getText() + "\'", ctx.getStart());
			return;
		}
	}

	@Override
	public void exitConstStringIdExpression(ConstStringIdExpressionContext ctx) {
		String val = "";
		String text = ctx.getText();
		if(	(text.startsWith("\"") && text.endsWith("\"")) ||
			(text.startsWith("\'") && text.endsWith("\'"))) {
			if(text.length() > 2) {
				val = text.substring(1, text.length()-1);
			}
		}
		else {
			DmlSyntacticValidatorHelper.notifyErrorListeners("something wrong while parsing string ... strange", ctx.start);
			return;
		}
			
		int linePosition = ctx.start.getLine();
		int charPosition = ctx.start.getCharPositionInLine();
		ctx.info.expr = new com.ibm.bi.dml.parser.StringIdentifier(val, DmlSyntacticErrorListener.currentFileName.peek(), linePosition, charPosition, linePosition, charPosition);
		setFileLineColumn(ctx.info.expr, ctx);
	}
	
	// --------------------------------------------------------------------
	
	@Override
	public void exitDataIdExpression(DataIdExpressionContext ctx) {
		ctx.info.expr = ctx.dataIdentifier().dataInfo.expr;
		int line = ctx.start.getLine();
		int col = ctx.start.getCharPositionInLine();
		ctx.info.expr.setAllPositions(DmlSyntacticValidatorHelper.getCurrentFileName(), line, col, line, col);
		setFileLineColumn(ctx.info.expr, ctx);
//		if(ctx.getChild(0) instanceof DataIdentifierContext) {
//			ctx.info.expr = ctx.dataIdentifier().dataInfo.expr;
//		}
//		else {
//			String msg = "cannot evaluate data expression ... strange";
//			DmlSyntacticValidatorHelper.notifyErrorListeners(msg, ctx.start);
//		}
	}
	
	@Override
	public void exitSimpleDataIdentifierExpression(SimpleDataIdentifierExpressionContext ctx) {
		// This is either a function, or variable with namespace
		// By default, it assigns to a data type
		ctx.dataInfo.expr = new DataIdentifier(ctx.getText());
		setFileLineColumn(ctx.dataInfo.expr, ctx);
	}
	
	@Override
	public void exitIndexedExpression(IndexedExpressionContext ctx) {
		ctx.dataInfo.expr = new IndexedIdentifier(ctx.name.getText(), false, false);
		setFileLineColumn(ctx.dataInfo.expr, ctx);
		try {
			ArrayList< ArrayList<com.ibm.bi.dml.parser.Expression> > exprList = new ArrayList< ArrayList<com.ibm.bi.dml.parser.Expression> >();
			
			ArrayList<com.ibm.bi.dml.parser.Expression> rowIndices = new ArrayList<Expression>();
			ArrayList<com.ibm.bi.dml.parser.Expression> colIndices = new ArrayList<Expression>();
			
			boolean isRowLower = (ctx.rowLower != null && !ctx.rowLower.isEmpty() && (ctx.rowLower.info.expr != null));
			boolean isRowUpper = (ctx.rowUpper != null && !ctx.rowUpper.isEmpty() && (ctx.rowUpper.info.expr != null));
			boolean isColLower = (ctx.colLower != null && !ctx.colLower.isEmpty() && (ctx.colLower.info.expr != null));
			boolean isColUpper = (ctx.colUpper != null && !ctx.colUpper.isEmpty() && (ctx.colUpper.info.expr != null));
			
			if(!isRowLower && !isRowUpper) {
				// both not set
				rowIndices.add(null); rowIndices.add(null);
			}
			else if(isRowLower && isRowUpper) {
				// both set
				rowIndices.add(ctx.rowLower.info.expr);
				rowIndices.add(ctx.rowUpper.info.expr);
			}
			else if(isRowLower && !isRowUpper) {
				// only row set
				rowIndices.add(ctx.rowLower.info.expr);
			}
			else {
				DmlSyntacticValidatorHelper.notifyErrorListeners("incorrect index expression for row", ctx.start);
				return;
			}
			
			if(!isColLower && !isColUpper) {
				// both not set
				colIndices.add(null); colIndices.add(null);
			}
			else if(isColLower && isColUpper) {
				colIndices.add(ctx.colLower.info.expr);
				colIndices.add(ctx.colUpper.info.expr);
			}
			else if(isColLower && !isColUpper) {
				colIndices.add(ctx.colLower.info.expr);
			}
			else {
				DmlSyntacticValidatorHelper.notifyErrorListeners("incorrect index expression for column", ctx.start);
				return;
			}
			
			
//			boolean rowIndexLowerSet = false;
//			boolean colIndexLowerSet = false;
//			
//			if(ctx.rowLower != null && !ctx.rowLower.isEmpty() && (ctx.rowLower.info.expr != null)) {
//				rowIndices.add(ctx.rowLower.info.expr);
//				rowIndexLowerSet = true;
//			}
//			else {
//				rowIndices.add(null);
//			}
//			if(ctx.rowUpper != null && !ctx.rowUpper.isEmpty() && (ctx.rowUpper.info.expr != null)) {
//				rowIndices.add(ctx.rowUpper.info.expr);
//				if(!rowIndexLowerSet) {
//					DmlSyntacticValidatorHelper.notifyErrorListeners("incorrect index expression for row", ctx.start);
//					return;
//				}
//			}
//			if(ctx.colLower != null && !ctx.colLower.isEmpty() && (ctx.colLower.info.expr != null)) {
//				colIndices.add(ctx.colLower.info.expr);
//				colIndexLowerSet = true;
//			}
//			else {
//				colIndices.add(null);
//			}
//			if(ctx.colUpper != null && !ctx.colUpper.isEmpty() && (ctx.colUpper.info.expr != null)) {
//				colIndices.add(ctx.colUpper.info.expr);
//				if(!colIndexLowerSet) {
//					DmlSyntacticValidatorHelper.notifyErrorListeners("incorrect index expression for column", ctx.start);
//					return;
//				}
//			}
			exprList.add(rowIndices);
			exprList.add(colIndices);
			((IndexedIdentifier) ctx.dataInfo.expr).setIndices(exprList);
		}
		catch(Exception e) {
			DmlSyntacticValidatorHelper.notifyErrorListeners("cannot set the indices", ctx.start);
			return;
		}
	}
	
	private com.ibm.bi.dml.parser.ConstIdentifier getConstIdFromString(String varValue, Token start) {
		// Both varName and varValue are correct
				int linePosition = start.getLine();
				int charPosition = start.getCharPositionInLine();
				try {
					long val = Long.parseLong(varValue);
					return new com.ibm.bi.dml.parser.IntIdentifier(val, DmlSyntacticErrorListener.currentFileName.peek(), linePosition, charPosition, linePosition, charPosition);
				}
				catch(Exception e) {
					try {
						double val = Double.parseDouble(varValue);
						return new com.ibm.bi.dml.parser.DoubleIdentifier(val, DmlSyntacticErrorListener.currentFileName.peek(), linePosition, charPosition, linePosition, charPosition);
					}
					catch(Exception e1) {
						try {
							if(varValue.compareTo("TRUE") == 0 || varValue.compareTo("FALSE") == 0) {
								boolean val = false;
								if(varValue.compareTo("TRUE") == 0) {
									val = true;
								}
								return new com.ibm.bi.dml.parser.BooleanIdentifier(val, DmlSyntacticErrorListener.currentFileName.peek(), linePosition, charPosition, linePosition, charPosition);
							}
							else {
								String val = "";
								String text = varValue;
								if(	(text.startsWith("\"") && text.endsWith("\"")) ||
									(text.startsWith("\'") && text.endsWith("\'"))) {
									if(text.length() > 2) {
										val = text.substring(1, text.length()-1);
									}
								}
								else {
									val = text;
									// the commandline parameters can be passed without any quotes
//									DmlSyntacticValidatorHelper.notifyErrorListeners("something wrong while parsing string ... strange", start);
//									return null;
								}
								return new com.ibm.bi.dml.parser.StringIdentifier(val, DmlSyntacticErrorListener.currentFileName.peek(), linePosition, charPosition, linePosition, charPosition);
							}
						}
						catch(Exception e3) {
							DmlSyntacticValidatorHelper.notifyErrorListeners("unable to cast the commandline parameter into int/double/boolean/string", start);
							return null;
						}
					}
				}
				
	}
	private void fillExpressionInfoCommandLineParameters(String varName, ExpressionInfo dataInfo, Token start) {
		
		if(!varName.startsWith("$")) {
			DmlSyntacticValidatorHelper.notifyErrorListeners("commandline param doesnot start with $ ... strange", start);
			return;
		}
		
		String varValue = null;
		for(Map.Entry<String, String> arg : Antlr4ParserWrapper.argVals.entrySet()) {
			if(arg.getKey().trim().compareTo(varName) == 0) {
				if(varValue != null) {
					DmlSyntacticValidatorHelper.notifyErrorListeners("multiple values passed for the parameter " + varName + " via commandline", start);
					return;
				}
				else {
					varValue = arg.getValue().trim();
				}
			}
		}
		
		if(varValue == null) {
			// DmlSyntacticValidatorHelper.notifyErrorListeners("the parameter " + varName + " either needs to be passed through commandline or initialized to default value", start);
			return;
		}
		
		// Command line param cannot be empty string
		// If you want to pass space, please quote it
		if(varValue.trim().compareTo("") == 0)
			return;
		
		dataInfo.expr = getConstIdFromString(varValue, start);
	}
	
	@Override
	public void exitCommandlineParamExpression(CommandlineParamExpressionContext ctx) {
		String varName = ctx.getText().trim();
		fillExpressionInfoCommandLineParameters(varName, ctx.dataInfo, ctx.start);
		if(ctx.dataInfo.expr == null) {
			// Check if the parent is ifdef
			if(!(ctx.parent instanceof IfdefAssignmentStatementContext)) {
				DmlSyntacticValidatorHelper.notifyErrorListeners("the parameter " + varName + " either needs to be passed through commandline or initialized to default value", ctx.start);
			}
		}
	}

	@Override
	public void exitCommandlinePositionExpression(CommandlinePositionExpressionContext ctx) {
		String varName = ctx.getText().trim();
		fillExpressionInfoCommandLineParameters(varName, ctx.dataInfo, ctx.start);
		if(ctx.dataInfo.expr == null) {
			// Check if the parent is ifdef
			if(!(ctx.parent instanceof IfdefAssignmentStatementContext)) {
				DmlSyntacticValidatorHelper.notifyErrorListeners("the parameter " + varName + " either needs to be passed through commandline or initialized to default value", ctx.start);
			}
		}
	}
	
	
	// --------------------------------------------------------------------
	
	@Override
	public void exitImportStatement(ImportStatementContext ctx) {
		String filePath = ctx.filePath.getText();
		String namespace = DMLProgram.DEFAULT_NAMESPACE;
		if(ctx.namespace != null && ctx.namespace.getText() != null && ctx.namespace.getText().isEmpty()) { 
			namespace = ctx.namespace.getText();
		}
		
		if(Antlr4ParserWrapper.currentPath != null) {
			filePath = Antlr4ParserWrapper.currentPath + File.separator + filePath;
		}
		
		File importedFile = new File(filePath);
		if(!importedFile.exists()) {
			DmlSyntacticValidatorHelper.notifyErrorListeners("cannot open the file " + filePath, ctx.start);
			return;
		}
		else {
			// Antlr4ParserWrapper antlr4Parser = new Antlr4ParserWrapper();
			DMLProgram prog = null;
			try {
				prog = (new Antlr4ParserWrapper()).doParse(filePath, null);
			} catch (ParseException e) {
				DmlSyntacticValidatorHelper.notifyErrorListeners("Exception found during importing a program from file " + filePath, ctx.start);
				return;
			}
	        // Custom logic whether to proceed ahead or not. Better than the current exception handling mechanism
			if(prog == null) {
				DmlSyntacticValidatorHelper.notifyErrorListeners("One or more errors found during importing a program from file " + filePath, ctx.start);
				return;
			}
			else {
				ctx.info.namespaces = new HashMap<String, DMLProgram>();
				ctx.info.namespaces.put(namespace, prog);
				ctx.info.stmt = new ImportStatement();
				((ImportStatement) ctx.info.stmt).setCompletePath(filePath);
				((ImportStatement) ctx.info.stmt).setFilePath(ctx.filePath.getText());
				((ImportStatement) ctx.info.stmt).setNamespace(namespace);
			}
		}
	}
	
	@Override
	public void exitAssignmentStatement(AssignmentStatementContext ctx) {
		if(ctx.targetList == null || ctx.targetList.size() != 1) {
			DmlSyntacticValidatorHelper.notifyErrorListeners("incorrect parsing for assignment", ctx.start);
			return;
		}
		String targetListText = ctx.targetList.get(0).getText(); 
		if(targetListText.startsWith("$")) {
			DmlSyntacticValidatorHelper.notifyErrorListeners("assignment of commandline parameters is not allowed. (Quickfix: try using someLocalVariable=ifdef(" + targetListText + ", default value))", ctx.start);
			return;
		}
		
		DataIdentifier target = null; 
		if(ctx.targetList.get(0).dataInfo.expr instanceof DataIdentifier) {
			target = (DataIdentifier) ctx.targetList.get(0).dataInfo.expr;
			com.ibm.bi.dml.parser.Expression source = ctx.source.info.expr;
			
			int line = ctx.start.getLine();
			int col = ctx.start.getCharPositionInLine();
			try {
				ctx.info.stmt = new com.ibm.bi.dml.parser.AssignmentStatement(target, source, line, col, line, col);
				setFileLineColumn(ctx.info.stmt, ctx);
			} catch (LanguageException e) {
				// TODO: extract more meaningful info from this exception.
				DmlSyntacticValidatorHelper.notifyErrorListeners("invalid assignment", ctx.targetList.get(0).start);
				return;
			} 
		}
		else {
			DmlSyntacticValidatorHelper.notifyErrorListeners("incorrect lvalue ... strange", ctx.targetList.get(0).start);
			return;
		}
		
	}

	
	private void setAssignmentStatement(DataIdentifier target, com.ibm.bi.dml.parser.Expression expression, StatementContext ctx) {
		try {
			ctx.info.stmt = new com.ibm.bi.dml.parser.AssignmentStatement(target, expression, ctx.start.getLine(), ctx.start.getCharPositionInLine(), ctx.start.getLine(), ctx.start.getCharPositionInLine());
			setFileLineColumn(ctx.info.stmt, ctx);
		} catch (LanguageException e) {
			// TODO: extract more meaningful info from this exception.
			DmlSyntacticValidatorHelper.notifyErrorListeners("invalid function call", ctx.start);
			return;
		}
	}
	
	private void setPrintStatement(FunctionCallAssignmentStatementContext ctx, String functionName) {
		ArrayList<com.ibm.bi.dml.parser.ParameterExpression> paramExpression = DmlSyntacticValidatorHelper.getParameterExpressionList(ctx.paramExprs);
		if(paramExpression.size() != 1) {
			DmlSyntacticValidatorHelper.notifyErrorListeners(functionName + "() has only one parameter", ctx.start);
			return;
		}
		com.ibm.bi.dml.parser.Expression expr = paramExpression.get(0).getExpr();
		if(expr == null) {
			DmlSyntacticValidatorHelper.notifyErrorListeners("cannot process " + functionName + "() function", ctx.start);
			return;
		}
		try {
			ctx.info.stmt = new com.ibm.bi.dml.parser.PrintStatement(functionName, expr);
		} catch (LanguageException e) {
			DmlSyntacticValidatorHelper.notifyErrorListeners("cannot process " + functionName + "() function", ctx.start);
			return;
		}
	}
	
	private void setOutputStatement(FunctionCallAssignmentStatementContext ctx) {
		ArrayList<com.ibm.bi.dml.parser.ParameterExpression> paramExpression = DmlSyntacticValidatorHelper.getParameterExpressionList(ctx.paramExprs);
		if(paramExpression.size() < 2){
			DmlSyntacticValidatorHelper.notifyErrorListeners("incorrect usage of write function (atleast 2 arguments required)", ctx.start);
			return;
		}
		if(paramExpression.get(0).getExpr() instanceof DataIdentifier) {
			//  && paramExpression.get(0).getName() == null
			// correct usage of identifier
			// if(paramExpression.get(1).getName() == null) {
				String fileName = DmlSyntacticValidatorHelper.getCurrentFileName();
				int line = ctx.start.getLine();
				int col = ctx.start.getCharPositionInLine();
				HashMap<String, Expression> varParams = new HashMap<String, Expression>();
				varParams.put(DataExpression.IO_FILENAME, paramExpression.get(1).getExpr());
				for(int i = 2; i < paramExpression.size(); i++) {
					// DataExpression.FORMAT_TYPE, DataExpression.DELIM_DELIMITER, DataExpression.DELIM_HAS_HEADER_ROW,  DataExpression.DELIM_SPARSE
					varParams.put(paramExpression.get(i).getName(), paramExpression.get(i).getExpr());
				}
				
				DataExpression  dataExpression = new DataExpression(DataOp.WRITE, varParams, fileName, line, col, line, col);
				ctx.info.stmt = new  com.ibm.bi.dml.parser.OutputStatement((DataIdentifier) paramExpression.get(0).getExpr(), DataOp.WRITE, fileName, line, col, line, col);
				setFileLineColumn(ctx.info.stmt, ctx);
				((com.ibm.bi.dml.parser.OutputStatement)ctx.info.stmt).setExprParams(dataExpression);
				return;
			//}
		}
		
		DmlSyntacticValidatorHelper.notifyErrorListeners("incorrect usage of write function", ctx.start);
		return;
		
	}
	
	@Override
	public void exitFunctionCallAssignmentStatement(FunctionCallAssignmentStatementContext ctx) {
		String fullyQualifiedFunctionName = ctx.name.getText();
		String [] fnNames = fullyQualifiedFunctionName.split("::");
		String functionName = "";
		String namespace = "";
		if(fnNames.length == 1) {
			namespace = DMLProgram.DEFAULT_NAMESPACE;
			functionName = fnNames[0].trim();
		}
		else if(fnNames.length == 2) {
			namespace = fnNames[0].trim();
			functionName = fnNames[1].trim();
		}
		else {
			DmlSyntacticValidatorHelper.notifyErrorListeners("incorrect function name", ctx.name);
			return;
		}
		
		if((functionName.compareTo("print") == 0 || functionName.compareTo("stop") == 0 ) && namespace.compareTo(DMLProgram.DEFAULT_NAMESPACE) == 0) {
			setPrintStatement(ctx, functionName);
			return;
		}
		else if(functionName.compareTo("write") == 0
				&& namespace.compareTo(DMLProgram.DEFAULT_NAMESPACE) == 0) {
			setOutputStatement(ctx);
			return;
		}
		
		boolean ignoreLValue = false;
		if(ctx.targetList == null || ctx.targetList.size() == 0 || ctx.targetList.get(0).isEmpty()) {
			DmlSyntacticValidatorHelper.notifyErrorListeners("function call needs to have lvalue (Quickfix: change it to \'tmpVar = " + functionName + "(...)\')", ctx.name);
		}
		String fileName = DmlSyntacticValidatorHelper.getCurrentFileName();
		int line = ctx.start.getLine();
		int col = ctx.start.getCharPositionInLine();
		
		ArrayList<com.ibm.bi.dml.parser.ParameterExpression> paramExpression = DmlSyntacticValidatorHelper.getParameterExpressionList(ctx.paramExprs);
//		if(functionName.compareTo("read") == 0 && paramExpression.size() > 0 && paramExpression.get(0).getName() == null) {
//			paramExpression.get(0).setName(DataExpression.IO_FILENAME);
//		}
		
		com.ibm.bi.dml.parser.FunctionCallIdentifier functCall = new FunctionCallIdentifier(paramExpression);
		try {
			functCall.setFunctionName(functionName);
			functCall.setFunctionNamespace(namespace);
		} catch (ParseException e1) {
			DmlSyntacticValidatorHelper.notifyErrorListeners("unable to process function " + functionName, ctx.start);
			 return;
		}
		
		DataIdentifier target = null; 
		if(!ignoreLValue) {
			if(ctx.targetList.get(0).dataInfo.expr instanceof DataIdentifier) {
				target = (DataIdentifier) ctx.targetList.get(0).dataInfo.expr;
			}
			else {
				DmlSyntacticValidatorHelper.notifyErrorListeners("incorrect lvalue ... strange", ctx.targetList.get(0).start);
				//target = new DataIdentifier(); // so as not to avoid null pointer
				return;
			}
		}
		
		if(!functionName.contains("::") || functionName.startsWith(DMLProgram.DEFAULT_NAMESPACE)) {
			// In global namespace, so it can be a builtin function
			if(!DmlSyntacticValidatorHelper.validateBuiltinFunctions(ctx)) {
				return; // it is a built-in function and validation failed, so donot proceed ahead.
			}
			// Double verification: verify passed function name is a (non-parameterized) built-in function.
			try {
				com.ibm.bi.dml.parser.BuiltinFunctionExpression bife = com.ibm.bi.dml.parser.BuiltinFunctionExpression.getBuiltinFunctionExpression(functionName, functCall.getParamExprs(), fileName, line, col, line, col);
				if (bife != null){
					// It is a builtin function
					setAssignmentStatement(target, bife, ctx);
					return;
				}
				
				com.ibm.bi.dml.parser.ParameterizedBuiltinFunctionExpression pbife = com.ibm.bi.dml.parser.ParameterizedBuiltinFunctionExpression.getParamBuiltinFunctionExpression(functionName, functCall.getParamExprs(), fileName, line, col, line, col);
				if (pbife != null){
					// It is a parameterized builtin function
					setAssignmentStatement(target, pbife, ctx);
					return;
				}
				
				// built-in read, rand ...
				com.ibm.bi.dml.parser.DataExpression dbife = com.ibm.bi.dml.parser.DataExpression.getDataExpression(functionName, functCall.getParamExprs(), fileName, line, col, line, col);
				if (dbife != null){
					setAssignmentStatement(target, dbife, ctx);
					return;
				}
			} catch(Exception e) {
				DmlSyntacticValidatorHelper.notifyErrorListeners("unable to process builtin function expression " + functionName  + ":" + e.getMessage(), ctx.start);
				// e.printStackTrace();
				return ;
			}
		}
		
		setAssignmentStatement(target, functCall, ctx);
	}
	
	@Override
	public void exitBuiltinFunctionExpression(BuiltinFunctionExpressionContext ctx) {
//		if(!DmlSyntacticValidatorHelper.validateBuiltinFunctions(ctx)) {
//			return; // it is a built-in function and validation failed, so donot proceed ahead.
//		}
		// Double verification: verify passed function name is a (non-parameterized) built-in function.
		String functionName = ctx.name.getText();
		String fileName = DmlSyntacticValidatorHelper.getCurrentFileName();
		int line = ctx.start.getLine();
		int col = ctx.start.getCharPositionInLine();
		ArrayList<com.ibm.bi.dml.parser.ParameterExpression> paramExpression = DmlSyntacticValidatorHelper.getParameterExpressionList(ctx.paramExprs);
//		if(functionName.compareTo("read") == 0 && paramExpression.size() > 0 && paramExpression.get(0).getName() == null) {
//			paramExpression.get(0).setName(DataExpression.IO_FILENAME);
//		}
		
		try {
			com.ibm.bi.dml.parser.BuiltinFunctionExpression bife = com.ibm.bi.dml.parser.BuiltinFunctionExpression.getBuiltinFunctionExpression(functionName, paramExpression, fileName, line, col, line, col);
			if (bife != null){
				// It is a builtin function
				ctx.info.expr = bife;
				return;
			}
			
			com.ibm.bi.dml.parser.ParameterizedBuiltinFunctionExpression pbife = com.ibm.bi.dml.parser.ParameterizedBuiltinFunctionExpression.getParamBuiltinFunctionExpression(functionName, paramExpression, fileName, line, col, line, col);
			if (pbife != null){
				// It is a parameterized builtin function
				ctx.info.expr = pbife;
				return;
			}
			
			// built-in read, rand ...
			com.ibm.bi.dml.parser.DataExpression dbife = com.ibm.bi.dml.parser.DataExpression.getDataExpression(functionName, paramExpression, fileName, line, col, line, col);
			if (dbife != null){
				ctx.info.expr = dbife;
				return;
			}
		} catch(Exception e) {
			DmlSyntacticValidatorHelper.notifyErrorListeners("unable to process builtin function expression " + functionName + ":" + e.getMessage(), ctx.start);
			return ;
		}
		DmlSyntacticValidatorHelper.notifyErrorListeners("only builtin functions allowed as part of expression", ctx.start);
	}
	
	private void setMultiAssignmentStatement(ArrayList<DataIdentifier> target, com.ibm.bi.dml.parser.Expression expression, StatementContext ctx) {
		ctx.info.stmt = new com.ibm.bi.dml.parser.MultiAssignmentStatement(target, expression);
		ctx.info.stmt.setAllPositions(DmlSyntacticValidatorHelper.getCurrentFileName(), ctx.start.getLine(), ctx.start.getCharPositionInLine(), ctx.start.getLine(), ctx.start.getCharPositionInLine());
		setFileLineColumn(ctx.info.stmt, ctx);
	}

	@Override
	public void exitFunctionCallMultiAssignmentStatement(
			FunctionCallMultiAssignmentStatementContext ctx) {
		String fullyQualifiedFunctionName = ctx.name.getText();
		String [] fnNames = fullyQualifiedFunctionName.split("::");
		String functionName = "";
		String namespace = "";
		if(fnNames.length == 1) {
			namespace = DMLProgram.DEFAULT_NAMESPACE;
			functionName = fnNames[0].trim();
		}
		else if(fnNames.length == 2) {
			namespace = fnNames[0].trim();
			functionName = fnNames[1].trim();
		}
		else {
			DmlSyntacticValidatorHelper.notifyErrorListeners("incorrect function name", ctx.name);
			return;
		}
		
		String fileName = DmlSyntacticValidatorHelper.getCurrentFileName();
		int line = ctx.start.getLine();
		int col = ctx.start.getCharPositionInLine();
		
		ArrayList<com.ibm.bi.dml.parser.ParameterExpression> paramExpression = DmlSyntacticValidatorHelper.getParameterExpressionList(ctx.paramExprs);
//		if(functionName.compareTo("read") == 0 && paramExpression.size() > 0 && paramExpression.get(0).getName() == null) {
//			paramExpression.get(0).setName(DataExpression.IO_FILENAME);
//		}
		
		com.ibm.bi.dml.parser.FunctionCallIdentifier functCall = new FunctionCallIdentifier(paramExpression);
		try {
			functCall.setFunctionName(functionName);
			functCall.setFunctionNamespace(namespace);
		} catch (ParseException e1) {
			DmlSyntacticValidatorHelper.notifyErrorListeners("unable to process function " + functionName, ctx.start);
			return;
		}
		
		ArrayList<DataIdentifier> targetList = new ArrayList<DataIdentifier>();
		for(DataIdentifierContext dataCtx : ctx.targetList) {
			if(dataCtx.dataInfo.expr instanceof DataIdentifier) {
				targetList.add((DataIdentifier) dataCtx.dataInfo.expr);
			}
			else {
				DmlSyntacticValidatorHelper.notifyErrorListeners("incorrect lvalue ... strange", dataCtx.start);
				//target = new DataIdentifier(); // so as not to avoid null pointer
				return;
			}
		}
		
		if(!functionName.contains("::") || functionName.startsWith(DMLProgram.DEFAULT_NAMESPACE)) {
			// In global namespace, so it can be a builtin function
//			if(!DmlSyntacticValidatorHelper.validateBuiltinFunctions(ctx)) {
//				return; // it is a built-in function and validation failed, so donot proceed ahead.
//			}
			// Double verification: verify passed function name is a (non-parameterized) built-in function.
			try {
				com.ibm.bi.dml.parser.BuiltinFunctionExpression bife = com.ibm.bi.dml.parser.BuiltinFunctionExpression.getBuiltinFunctionExpression(functionName, functCall.getParamExprs(), fileName, line, col, line, col);
				if (bife != null){
					// It is a builtin function
					setMultiAssignmentStatement(targetList, bife, ctx);
					return;
				}
				
				com.ibm.bi.dml.parser.ParameterizedBuiltinFunctionExpression pbife = com.ibm.bi.dml.parser.ParameterizedBuiltinFunctionExpression.getParamBuiltinFunctionExpression(functionName, functCall.getParamExprs(), fileName, line, col, line, col);
				if (pbife != null){
					// It is a parameterized builtin function
					setMultiAssignmentStatement(targetList, pbife, ctx);
					return;
				}
				
				// built-in read, rand ...
				com.ibm.bi.dml.parser.DataExpression dbife = com.ibm.bi.dml.parser.DataExpression.getDataExpression(functionName, functCall.getParamExprs(), fileName, line, col, line, col);
				if (dbife != null){
					setMultiAssignmentStatement(targetList, dbife, ctx);
					return;
				}
			} catch(Exception e) {
				DmlSyntacticValidatorHelper.notifyErrorListeners("unable to process builtin function expression " + functionName  + ":" + e.getMessage(), ctx.start);
				// e.printStackTrace();
				return;
			}
		}
		
		setMultiAssignmentStatement(targetList, functCall, ctx);
	}
	
	private com.ibm.bi.dml.parser.StatementBlock getStatementBlock(com.ibm.bi.dml.parser.Statement current) {
		return Antlr4ParserWrapper.getStatementBlock(current);
	}
	
	@Override
	public void exitIfStatement(IfStatementContext ctx) {
		com.ibm.bi.dml.parser.IfStatement ifStmt = new IfStatement();
		com.ibm.bi.dml.parser.ConditionalPredicate predicate = new ConditionalPredicate(ctx.predicate.info.expr);
		ifStmt.setConditionalPredicate(predicate);
		String fileName = DmlSyntacticValidatorHelper.getCurrentFileName();
		int line = ctx.start.getLine();
		int col = ctx.start.getCharPositionInLine();
		ifStmt.setAllPositions(fileName, line, col, line, col);
		
		if(ctx.ifBody.size() > 0) {
			for(StatementContext stmtCtx : ctx.ifBody) {
				ifStmt.addStatementBlockIfBody(getStatementBlock(stmtCtx.info.stmt));
			}
			ifStmt.mergeStatementBlocksIfBody();
		}
		
		if(ctx.elseBody.size() > 0) {
			for(StatementContext stmtCtx : ctx.elseBody) {
				ifStmt.addStatementBlockElseBody(getStatementBlock(stmtCtx.info.stmt));
			}
			ifStmt.mergeStatementBlocksElseBody();
		}
		
		ctx.info.stmt = ifStmt;
		setFileLineColumn(ctx.info.stmt, ctx);
	}
	
	@Override
	public void exitWhileStatement(WhileStatementContext ctx) {
		com.ibm.bi.dml.parser.WhileStatement whileStmt = new com.ibm.bi.dml.parser.WhileStatement();
		com.ibm.bi.dml.parser.ConditionalPredicate predicate = new ConditionalPredicate(ctx.predicate.info.expr);
		whileStmt.setPredicate(predicate);
		String fileName = DmlSyntacticValidatorHelper.getCurrentFileName();
		int line = ctx.start.getLine();
		int col = ctx.start.getCharPositionInLine();
		whileStmt.setAllPositions(fileName, line, col, line, col);
		
		if(ctx.body.size() > 0) {
			for(StatementContext stmtCtx : ctx.body) {
				whileStmt.addStatementBlock(getStatementBlock(stmtCtx.info.stmt));
			}
			whileStmt.mergeStatementBlocks();
		}
		
		ctx.info.stmt = whileStmt;
		setFileLineColumn(ctx.info.stmt, ctx);
	}
	
	@Override
	public void exitForStatement(ForStatementContext ctx) {
		com.ibm.bi.dml.parser.ForStatement forStmt = new ForStatement();
		String fileName = DmlSyntacticValidatorHelper.getCurrentFileName();
		int line = ctx.start.getLine();
		int col = ctx.start.getCharPositionInLine();
		
		com.ibm.bi.dml.parser.DataIdentifier iterVar = new DataIdentifier(ctx.iterVar.getText());
		HashMap<String, String> parForParamValues = null;
		com.ibm.bi.dml.parser.Expression incrementExpr = new com.ibm.bi.dml.parser.IntIdentifier(1, fileName, line, col, line, col);
		if(ctx.iterPred.info.increment != null && ctx.iterPred.info.increment != null) {
			incrementExpr = ctx.iterPred.info.increment;
		}
		com.ibm.bi.dml.parser.IterablePredicate predicate = new IterablePredicate(iterVar, ctx.iterPred.info.from, ctx.iterPred.info.to, incrementExpr, parForParamValues, fileName, line, col, line, col);
		forStmt.setPredicate(predicate);
		
		if(ctx.body.size() > 0) {
			for(StatementContext stmtCtx : ctx.body) {
				forStmt.addStatementBlock(getStatementBlock(stmtCtx.info.stmt));
			}
			forStmt.mergeStatementBlocks();
		}
		ctx.info.stmt = forStmt;
		setFileLineColumn(ctx.info.stmt, ctx);
	}

	@Override
	public void exitParForStatement(ParForStatementContext ctx) {
		com.ibm.bi.dml.parser.ParForStatement parForStmt = new com.ibm.bi.dml.parser.ParForStatement();
		String fileName = DmlSyntacticValidatorHelper.getCurrentFileName();
		int line = ctx.start.getLine();
		int col = ctx.start.getCharPositionInLine();
		
		com.ibm.bi.dml.parser.DataIdentifier iterVar = new DataIdentifier(ctx.iterVar.getText());
		HashMap<String, String> parForParamValues = new HashMap<String, String>();
		if(ctx.parForParams != null && ctx.parForParams.size() > 0) {
			for(StrictParameterizedExpressionContext parForParamCtx : ctx.parForParams) {
				parForParamValues.put(parForParamCtx.paramName.getText(), parForParamCtx.paramVal.getText());
			}
		}
		
		com.ibm.bi.dml.parser.Expression incrementExpr = new com.ibm.bi.dml.parser.IntIdentifier(1, fileName, line, col, line, col);
		
		if(ctx.iterPred.info.increment != null && ctx.iterPred.info.increment != null) {
			incrementExpr = ctx.iterPred.info.increment;
		}
		com.ibm.bi.dml.parser.IterablePredicate predicate = new IterablePredicate(iterVar, ctx.iterPred.info.from, ctx.iterPred.info.to, incrementExpr, parForParamValues, fileName, line, col, line, col);
		parForStmt.setPredicate(predicate);
		if(ctx.body.size() > 0) {
			for(StatementContext stmtCtx : ctx.body) {
				parForStmt.addStatementBlock(getStatementBlock(stmtCtx.info.stmt));
			}
			parForStmt.mergeStatementBlocks();
		}
		ctx.info.stmt = parForStmt;
		setFileLineColumn(ctx.info.stmt, ctx);
	}
	
	
	@Override
	public void exitDmlprogram(DmlprogramContext ctx) { }
	

	// ----------------------------------------------------------------------
	@Override
	public void exitValueType(ValueTypeContext ctx) { }
	@Override
	public void exitMl_type(Ml_typeContext ctx) { }
	
	private Vector<com.ibm.bi.dml.parser.DataIdentifier> getFunctionParameters(List<TypedArgNoAssignContext> ctx) {
		Vector<com.ibm.bi.dml.parser.DataIdentifier> retVal = new Vector<DataIdentifier>();
		for(TypedArgNoAssignContext paramCtx : ctx) {
			com.ibm.bi.dml.parser.DataIdentifier dataId = new DataIdentifier(paramCtx.paramName.getText());
			String dataType = null;
			String valueType = paramCtx.paramType.valueType().getText();
			
			if(paramCtx.paramType == null || paramCtx.paramType.dataType() == null 
					|| paramCtx.paramType.dataType().getText() == null || paramCtx.paramType.dataType().getText().isEmpty()) {
				dataType = "scalar";
			}
			else {
				dataType = paramCtx.paramType.dataType().getText();
			}
			
			if(dataType.compareTo("matrix") == 0 || dataType.compareTo("Matrix") == 0) {
				// matrix
				dataId.setDataType(DataType.MATRIX);
			}
			else if(dataType.compareTo("scalar") == 0 || dataType.compareTo("Scalar") == 0) {
				// scalar
				dataId.setDataType(DataType.SCALAR);
			}
			else {
				DmlSyntacticValidatorHelper.notifyErrorListeners("invalid datatype " + dataType, paramCtx.start);
				return null;
			}
			
			if(valueType.compareTo("int") == 0 || valueType.compareTo("integer") == 0
				|| valueType.compareTo("Int") == 0 || valueType.compareTo("Integer") == 0) {
				dataId.setValueType(ValueType.INT);
			}
			else if(valueType.compareTo("string") == 0 || valueType.compareTo("String") == 0) {
				dataId.setValueType(ValueType.STRING);
			}
			else if(valueType.compareTo("boolean") == 0 || valueType.compareTo("Boolean") == 0) {
				dataId.setValueType(ValueType.BOOLEAN);
			}
			else if(valueType.compareTo("double") == 0 || valueType.compareTo("Double") == 0) {
				dataId.setValueType(ValueType.DOUBLE);
			}
			else if(valueType.compareTo("bool") == 0) {
				DmlSyntacticValidatorHelper.notifyErrorListeners("invalid valuetype " + valueType + " (Quickfix: use \'boolean\' instead)", paramCtx.start);
				return null;
			}
			else {
				DmlSyntacticValidatorHelper.notifyErrorListeners("invalid valuetype " + valueType, paramCtx.start);
				return null;
			}
			retVal.add(dataId);
		}
		return retVal;
	}
	
	@Override
	public void exitInternalFunctionDefExpression(InternalFunctionDefExpressionContext ctx) {
		com.ibm.bi.dml.parser.FunctionStatement functionStmt = new com.ibm.bi.dml.parser.FunctionStatement();
		
		Vector<com.ibm.bi.dml.parser.DataIdentifier> functionInputs  = getFunctionParameters(ctx.inputParams);
		((com.ibm.bi.dml.parser.FunctionStatement) functionStmt).setInputParams(functionInputs);
		
		// set function outputs
		Vector<com.ibm.bi.dml.parser.DataIdentifier> functionOutputs = getFunctionParameters(ctx.outputParams);
		((com.ibm.bi.dml.parser.FunctionStatement) functionStmt).setOutputParams(functionOutputs);
		
		// set function name
		functionStmt.setName(ctx.name.getText());
		
		
		if(ctx.body.size() > 0) {
			// handle function body
			// Create arraylist of one statement block
			ArrayList<com.ibm.bi.dml.parser.StatementBlock> body = new ArrayList<StatementBlock>();
			for(StatementContext stmtCtx : ctx.body) {
				body.add(getStatementBlock(stmtCtx.info.stmt));
			}
			((com.ibm.bi.dml.parser.FunctionStatement) functionStmt).setBody(body);
			((com.ibm.bi.dml.parser.FunctionStatement) functionStmt).mergeStatementBlocks();
		}
		else {
			DmlSyntacticValidatorHelper.notifyErrorListeners("functions with no statements are not allowed", ctx.start);
			return;
		}
		
		ctx.info.stmt = functionStmt;
		setFileLineColumn(ctx.info.stmt, ctx);
		ctx.info.functionName = ctx.name.getText();
	}
	
	@Override
	public void exitExternalFunctionDefExpression(ExternalFunctionDefExpressionContext ctx) {
		com.ibm.bi.dml.parser.ExternalFunctionStatement functionStmt = new com.ibm.bi.dml.parser.ExternalFunctionStatement();
		
		Vector<com.ibm.bi.dml.parser.DataIdentifier> functionInputs  = getFunctionParameters(ctx.inputParams);
		((com.ibm.bi.dml.parser.ExternalFunctionStatement) functionStmt).setInputParams(functionInputs);
		
		// set function outputs
		Vector<com.ibm.bi.dml.parser.DataIdentifier> functionOutputs = getFunctionParameters(ctx.outputParams);
		((com.ibm.bi.dml.parser.ExternalFunctionStatement) functionStmt).setOutputParams(functionOutputs);
		
		// set function name
		functionStmt.setName(ctx.name.getText());
		
		// set other parameters
		HashMap<String, String> otherParams = new HashMap<String,String>();
		boolean atleastOneClassName = false;
		for(StrictParameterizedKeyValueStringContext otherParamCtx : ctx.otherParams){
			String paramName = otherParamCtx.paramName.getText();
			String val = "";
			String text = otherParamCtx.paramVal.getText();
			// First unquote the string
			if(	(text.startsWith("\"") && text.endsWith("\"")) ||
				(text.startsWith("\'") && text.endsWith("\'"))) {
				if(text.length() > 2) {
					val = text.substring(1, text.length()-1);
				}
				// Empty value allowed
			}
			else {
				DmlSyntacticValidatorHelper.notifyErrorListeners("the value of user parameter for external function should be of type string", ctx.start);
				return;
			}
			otherParams.put(paramName, val);
			if(paramName.compareTo("classname") == 0) {
				atleastOneClassName = true;
			}
		}
		functionStmt.setOtherParams(otherParams);
		if(!atleastOneClassName) {
			DmlSyntacticValidatorHelper.notifyErrorListeners("the parameter \'className\' needs to be passed for externalFunction", ctx.start);
			return;
		}
		
//		if(ctx.body.size() > 0) {
//			// handle function body
//			// Create arraylist of one statement block
//			ArrayList<com.ibm.bi.dml.parser.StatementBlock> body = new ArrayList<StatementBlock>();
//			for(StatementContext stmtCtx : ctx.body) {
//				body.add(getStatementBlock(stmtCtx.info.stmt));
//			}
//			((com.ibm.bi.dml.parser.ExternalFunctionStatement) functionStmt).setBody(body);
//			((com.ibm.bi.dml.parser.ExternalFunctionStatement) functionStmt).mergeStatementBlocks();
//		}
//		else {
//			DmlSyntacticValidatorHelper.notifyErrorListeners("functions with no statements are not allowed", ctx.start);
//			return;
//		}
		
		ctx.info.stmt = functionStmt;
		setFileLineColumn(ctx.info.stmt, ctx);
		ctx.info.functionName = ctx.name.getText();
	}
	
	
	@Override
	public void exitPathStatement(PathStatementContext ctx) {
		com.ibm.bi.dml.parser.PathStatement stmt = new PathStatement(ctx.pathValue.getText());
		Antlr4ParserWrapper.currentPath = ctx.pathValue.getText() + File.separator;
		ctx.info.stmt = stmt;
	}
	
	@Override
	public void exitIfdefAssignmentStatement(IfdefAssignmentStatementContext ctx) {
		if(!ctx.commandLineParam.getText().startsWith("$")) {
			DmlSyntacticValidatorHelper.notifyErrorListeners("the first argument of ifdef function should be a commandline argument parameter (which starts with $)", ctx.commandLineParam.start);
			return;
		}
		
		if(ctx.targetList == null || ctx.targetList.size() != 1) {
			DmlSyntacticValidatorHelper.notifyErrorListeners("incorrect parsing for ifdef function", ctx.start);
			return;
		}
		String targetListText = ctx.targetList.get(0).getText(); 
		if(targetListText.startsWith("$")) {
			DmlSyntacticValidatorHelper.notifyErrorListeners("lhs of ifdef function cannot be a commandline parameters. Use local variable instead", ctx.start);
			return;
		}
		
		DataIdentifier target = null; 
		if(ctx.targetList.get(0).dataInfo.expr instanceof DataIdentifier) {
			target = (DataIdentifier) ctx.targetList.get(0).dataInfo.expr;
			com.ibm.bi.dml.parser.Expression source = null;
			if(ctx.commandLineParam.dataInfo.expr != null) {
				// Since commandline parameter is set
				// The check of following is done in fillExpressionInfoCommandLineParameters:
				// Command line param cannot be empty string
				// If you want to pass space, please quote it
				source = ctx.commandLineParam.dataInfo.expr;
			}
			else {
				source = ctx.source.info.expr;
			}
			
			int line = ctx.start.getLine();
			int col = ctx.start.getCharPositionInLine();
			try {
				ctx.info.stmt = new com.ibm.bi.dml.parser.AssignmentStatement(target, source, line, col, line, col);
				setFileLineColumn(ctx.info.stmt, ctx);
			} catch (LanguageException e) {
				DmlSyntacticValidatorHelper.notifyErrorListeners("invalid assignment for ifdef function", ctx.targetList.get(0).start);
				return;
			} 
			
		}
		else {
			DmlSyntacticValidatorHelper.notifyErrorListeners("incorrect lvalue in ifdef function... strange", ctx.targetList.get(0).start);
			return;
		}
		
	}
	
	// ----------------------------------------------------------------------
	@Override
	public void exitParameterizedExpression(ParameterizedExpressionContext ctx) { }


	@Override
	public void exitStrictParameterizedExpression(StrictParameterizedExpressionContext ctx) { }

	@Override
	public void exitTypedArgNoAssign(TypedArgNoAssignContext ctx) { }
	@Override
	public void enterIfdefAssignmentStatement(IfdefAssignmentStatementContext ctx) { }
	@Override
	public void enterMatrixDataTypeCheck(MatrixDataTypeCheckContext ctx) { }
	@Override
	public void exitMatrixDataTypeCheck(MatrixDataTypeCheckContext ctx) {
		if(		ctx.ID().getText().compareTo("matrix") == 0 
				|| ctx.ID().getText().compareTo("Matrix") == 0 
				|| ctx.ID().getText().compareTo("Scalar") == 0
				|| ctx.ID().getText().compareTo("scalar") == 0
				) {
			// Do nothing
		}
		else {
			DmlSyntacticValidatorHelper.notifyErrorListeners("incorrect datatype (expected matrix or scalar)", ctx.start);
		}
	}
	
	@Override
	public void enterBuiltinFunctionExpression(BuiltinFunctionExpressionContext ctx) {}
	@Override
	public void enterStrictParameterizedKeyValueString(StrictParameterizedKeyValueStringContext ctx) { }
	@Override
	public void exitStrictParameterizedKeyValueString(StrictParameterizedKeyValueStringContext ctx) {}
	@Override
	public void enterIterablePredicateColonExpression(IterablePredicateColonExpressionContext ctx) {}
	@Override
	public void enterIterablePredicateSeqExpression(IterablePredicateSeqExpressionContext ctx) { }
	
	@Override
	public void exitIterablePredicateColonExpression(IterablePredicateColonExpressionContext ctx) {
		ctx.info.from = ctx.from.info.expr;
		ctx.info.to = ctx.to.info.expr;
		ctx.info.increment = null;
	}
	
	@Override
	public void exitIterablePredicateSeqExpression(IterablePredicateSeqExpressionContext ctx) {
		if(ctx.ID().getText().compareTo("seq") != 0) {
			DmlSyntacticValidatorHelper.notifyErrorListeners("incorrect function:\'" + ctx.ID().getText() + "\'. expected \'seq\'", ctx.start);
			return;
		}
		ctx.info.from = ctx.from.info.expr;
		ctx.info.to = ctx.to.info.expr;
		ctx.info.increment = ctx.increment.info.expr;		
	}
	
	@Override
	public void enterConstFalseExpression(ConstFalseExpressionContext ctx) { }
	@Override
	public void enterConstTrueExpression(ConstTrueExpressionContext ctx) { }
	
	@Override
	public void exitConstFalseExpression(ConstFalseExpressionContext ctx) {
		boolean val = false;
		int linePosition = ctx.start.getLine();
		int charPosition = ctx.start.getCharPositionInLine();
		ctx.info.expr = new com.ibm.bi.dml.parser.BooleanIdentifier(val, DmlSyntacticErrorListener.currentFileName.peek(), linePosition, charPosition, linePosition, charPosition);
		setFileLineColumn(ctx.info.expr, ctx);
	}
	
	
	@Override
	public void exitConstTrueExpression(ConstTrueExpressionContext ctx) {
		boolean val = true;
		int linePosition = ctx.start.getLine();
		int charPosition = ctx.start.getCharPositionInLine();
		ctx.info.expr = new com.ibm.bi.dml.parser.BooleanIdentifier(val, DmlSyntacticErrorListener.currentFileName.peek(), linePosition, charPosition, linePosition, charPosition);
		setFileLineColumn(ctx.info.expr, ctx);
	}
	
		
}