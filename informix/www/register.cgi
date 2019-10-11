#!/usr/local/bin/perl

print "Content-type: text/html\n\n";
print "<html>\n";
print "<head><title>수강신청</title></head>\n";
print "<body bgcolor=white>\n";

if ($ENV{'REQUEST_METHOD'} eq 'GET') {
  (@keyword) = split(/&/, $ENV{'QUERY_STRING'});
} elsif ($ENV{'REQUEST_METHOD'} eq 'POST') {
  while (<>) {
    (@keyword) = split(/&/, $_);
  }
} else {
  print "Unknown request method<br>\n";
  exit(0);
}

$service = 0;

foreach $keyword (@keyword) {
  ($variable, $value) = split(/=/, $keyword);
  $value = urldecode($value);
  chomp $variable;
  chomp $value;
  #print "$variable = $value<br>\n";
  if ($variable eq 'service') {
    if ($value eq 'register') {
      $service = 1;
    } elsif ($value eq 'timetable') {
      $service = 2;
    } elsif ($value eq 'classinfo') {
      $service = 3;
    } elsif ($value eq 'status') {
      $service = 4;
    } else {
      print "Unknown value type, $value<br>\n";
    }
  } elsif ($variable eq 'name') {
    if (not $value and not $student_name) {
      $value = "NULL";
    }
    $student_name = $value;
  } elsif ($variable eq 'number') {
    if (not $value and not $student_number) {
      $value = "NULL";
    }
    $student_number = $value;
  } elsif ($variable eq 'number1') {
    if (not $value and not $student_number1) {
      $value = "NULL";
    }
    $student_number1 = $value;
  } elsif ($variable eq 'number2') {
    if (not $value and not $student_number) {
      $value = "NULL";
    }
    $student_number = $student_number1 . "-$value";
  } elsif ($variable eq 'college') {
    if (not $value and not $college) {
      $value = "NULL";
    }
    $college = $value;
  } elsif ($variable eq 'dept') {
    if (not $value and not $dept) {
      $value = "NULL";
    }
    $dept = $value;
  } elsif ($variable eq 'prof') {
    if (not $value and not $prof) {
      $value = "NULL";
    }
    $prof = $value;
  } elsif ($variable eq 'newclass') {
    if (not $value and not $class) {
      $value = "NULL";
    }
    $newclass = $value;
  } elsif ($variable eq 'class') {
    if (not $value and not $class) {
      $value = "NULL";
    }
    $class = $value;
  } elsif ($variable eq 'act') {
    if ($value eq 'insert') {
      $service = 5;
    } elsif ($value eq 'delete') {
      $service = 6;
    } elsif ($value eq 'update') {
      $service = 7;
    }
  } elsif ($variable eq 'select') {
    if (not $value) {
      $value = "NULL";
    }
    $select = $value; 
  } else {
    print "Unknown variable type, $variable<br>\n";
  }
}
  
if ($service == 1) {
  $command = "$service \'$student_number\' \'$student_name\'";
} elsif ($service == 2) {
  $command = "$service \'$student_number\' \'$student_name\'";
} elsif ($service == 3) {
  $command = "$service \'$select\' \'$college\' \'$dept\' \'$prof\' \'$class\'";
} elsif ($service == 4) {
  $command = "$service \'$class\'";
} elsif ($service == 5) {
  $command = "$service \'$student_number\' \'$newclass\'";
} elsif ($service == 6) {
  $command = "$service \'$student_number\' \'$class\'";
} elsif ($service == 7) {
  $command = "$service \'$student_number\' \'$class\' \'$newclass\'";
} else {
  print "Unknown service type, $service<br>\n";
}

$result = `./test.sh $command`;
print "$result<br>\n";

sub urldecode {
  my $string = shift(@_);
  my $decoded;
  my $char;
  my @list;

  @list = split //, $string;
  while (($char = shift @list) ne '') {
    if ($char eq '%') {
      $ch1 = shift @list;
      $ch2 = shift @list;
      $decoded .= sprintf "%c", hex("$ch1$ch2");
    } else {
      $char =~ s/\+/ /g;
      $decoded .= $char;
    }
  }
  return $decoded;
}

