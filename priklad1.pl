use HTML::Strip;
use Data::Dumper;
use Getopt::Long;

my $hs = HTML::Strip->new();
my $filename = 'input.txt';
my $outputfilename = 'output.txt';
my $minLengthOfWord = 2;
my $minOfOccurence = 1;
my $TPweight = 0;
my $TFweight = 0;
my $global_weight = 0;
my %documents;
my %word_counts;


GetOptions(
    'input-file=s'       => \$filename,
    'output-file=s'      => \$outputfilename,
    'min-length=i'       => \$minLengthOfWord,
    'min-occurrences=i'  => \$minOfOccurence,
    'TPweight=i'     => \$TPweight,
    'TFweight=i'     => \$TFweight,
    'global-weight=i'    => \$global_weight,
) or die "Error in command line arguments.\n";


print "input-file: $filename\n";
print "output-file: $outputfilename\n";
print "min-length: $minLengthOfWord\n";
print "min-occurrences: $minOfOccurence\n";
print "TPweight: $TPweight\n";
print "TFweight: $TFweight\n";
print "global_weight: $global_weight\n";


open(INPUT, '<', $filename) or die $!;
print("File $filename opened successfully!\n");

while (my $row = <INPUT>) {
    chomp($row);
    my ($classOfDocument, $textToProcess) = split(/\t/, $row);
    $textToProcess = $hs->parse($textToProcess);
    $textToProcess =~ s/\d+//g;
    $textToProcess =~ s/[[:punct:]]//g;
    $textToProcess = lc($textToProcess);

   if (not exists $documents{$classOfDocument}) {
    $documents{$classOfDocument} = [$textToProcess];
    }
    else {
        push @{$documents{$classOfDocument}}, $textToProcess;
    }
    
    my @words = split(' ', $textToProcess);
    foreach my $word (@words) {
        $word_counts{$word}++;
    }
}
close(INPUT);


my @all_words;
foreach my $word (keys %word_counts) {
    if (length($word) >= $minLengthOfWord && $word_counts{$word} >= $minOfOccurence) {
        push(@all_words, $word);
    }
}


my %idf;
my $total_documents = scalar(keys %documents);

foreach my $word (@all_words) {
    my $document_count = 0;
    foreach my $class (keys %documents) {
        foreach my $document (@{$documents{$class}}) {
            if ($document =~ /\b$word\b/) {
                $document_count++;
            }
        }
    }
        $idf{$word} = log($total_documents / $document_count);
}


open(OUTPUT, '>', $outputfilename) or die $!;
print OUTPUT join("\t\t\t", @all_words), "\t\t\t_CLASS_\n";

foreach my $class (keys %documents) {
    foreach my $document (@{$documents{$class}}) {
        my %tf;
        my %tp;
        my @words = split(' ', $document);

        
        foreach my $word (@words) {
            $tf{$word}++;
            if($document =~ /$word/){
                $tp{$word} = 1;
            }else{
                $tp{$word} = 0;
            }
           
        }

        if ($TFweight) {
        
        my @tf_weights;
        my $sum_of_weights = 0;  

        foreach my $word (@all_words) {
            my $tf_weight;
                if (exists $tf{$word}) {
                    $tf_weight = $tf{$word};
                } else {
                    $tf_weight = 0;
                }

            if ($global_weight) {
                 if (exists $idf{$word}) {
                    $tf_weight *= $idf{$word};
                } 
                $sum_of_weights += abs($tf_weight);
            }

            push @tf_weights, abs($tf_weight);
        }

       
       if ($global_weight) {
     my $total_weights = scalar(@tf_weights);
   foreach my $i (0 .. $total_weights) {
        if ($sum_of_weights != 0) {
            $tf_weights[$i] /= $sum_of_weights;
        }
        $tf_weights[$i] = sprintf("%.2f", $tf_weights[$i]);
    }
}


        print OUTPUT join("\t\t\t", @tf_weights), "\t$class\n";
    }    elsif ($TPweight) {
            
            my @tp_weights;
            foreach my $word (@all_words) {
               my $tp_weight;
                if (exists $tp{$word}) {
                    $tp_weight = $tp{$word};
                } else {
                    $tp_weight = 0;
                }
   
                push @tp_weights, $tp_weight;
            }
            print OUTPUT join("\t\t\t", @tp_weights), "\t$class\n";
        }
    }
}

close(OUTPUT);
                  







print "Documents by class:\n";
foreach my $class (keys %documents) {
    print "Class: $class\n";
    foreach my $document (@{ $documents{$class} }) {
        print "- $document\n";
    }
}

print "All words: @all_words\n";
