package dml.runtime.matrix.mapred;

import java.io.BufferedInputStream;
import java.io.IOException;
import java.util.ArrayList;

import org.apache.hadoop.fs.FSDataInputStream;
import org.apache.hadoop.fs.FileStatus;
import org.apache.hadoop.fs.FileSystem;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.mapred.FileSplit;
import org.apache.hadoop.mapred.InputSplit;
import org.apache.hadoop.mapred.JobConf;
import org.apache.hadoop.mapred.TextInputFormat;

/**
 * <p>Genereates a single mapper for each input line.</p>
 * <p>Should not be used for large files, as everything is read to create the splits.</p>
 * 
 * @author ytian
 * @author schnetter
 */
public class MapPerLineTextInputFormat extends TextInputFormat
{
	public InputSplit[] getSplits(JobConf job, int numSplits) throws IOException
	{
		FileStatus[] files = listStatus(job);
		ArrayList<FileSplit> splits = new ArrayList<FileSplit>(numSplits);
		
		for(FileStatus file : files)
		{
			Path path = file.getPath();
			FileSystem fs = path.getFileSystem(job);
			FSDataInputStream fsIn = fs.open(path);
			BufferedInputStream in = new BufferedInputStream(fsIn);
			long pos = 0;
			long startPos = 0;
			int b = in.read();
			int lastChar;
			
			// A line is considered to be terminated by any one of a line feed ('\n'), a carriage return ('\r'), or a
			// carriage return followed immediately by a linefeed.
			while(b != -1)
			{
				lastChar = b;
				b = in.read();
				pos++;
				
				if(lastChar != '\n' && lastChar != '\r')
					continue;
				
				if(b == '\n')
				{
					b = in.read();
					pos++;
				}
				
				splits.add(new FileSplit(path, startPos, (pos - startPos), job));
				startPos = pos;
			}
			
			in.close();
		}
		
		LOG.debug("Total # of splits: " + splits.size());
		return splits.toArray(new FileSplit[splits.size()]);
	}
}
