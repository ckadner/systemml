#!/usr/bin/perl

while($line = <STDIN>){
    chomp($line);
    @arr = split(/ /, $line);
    $row = $arr[0];
    $col = $arr[1];

    #$val = $arr[2];
    #$new_col = $col - 54;

    $val = 1.0;
    $new_col = $col + 21831;

    print "$row $new_col $val\n";
}
