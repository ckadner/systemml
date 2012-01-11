package dml.meta;

import java.io.IOException;

import org.apache.hadoop.mapred.OutputCollector;

import dml.runtime.matrix.io.MatrixCell;
import dml.runtime.matrix.io.MatrixIndexes;
import dml.runtime.matrix.io.MatrixValue;
import dml.runtime.matrix.io.Pair;

public class RowMapperMethod extends MapperMethod {
	public RowMapperMethod(PartitionParams pp) {
		super(pp) ;
	}

	@Override
	void execute(Pair<MatrixIndexes, MatrixValue> pair, OutputCollector out)
			throws IOException {
		MatrixCell value = (MatrixCell) pair.getValue() ;
		pols.set(pair.getKey().getRowIndex()) ;
		partialBuffer.set(1, (int) pair.getKey().getColumnIndex(), value.getValue()) ;
		out.collect(pols, partialBuffer) ;
	}
}
