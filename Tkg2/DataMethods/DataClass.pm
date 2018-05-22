package Tkg2::DataMethods::DataClass;

=head1 LICENSE

 This Tkg2 module is authored by the enigmatic William H. Asquith.
     
 This program is absolutely free software; 

Author of this software makes no claim whatsoever about suitability,
reliability, editability or usability of this product. If you can use it,
you are in luck, if not, I should not be and can not be held responsible.
Furthermore, portions of this software (tkg2 and related modules) were
developed by the Author as an employee of the U.S. Geological Survey
Water-Resources Division, neither the USGS, the Department of the
Interior, or other entities of the Federal Government make any claim
whatsoever about suitability, reliability, editability or usability
of this product.

=cut

# $Author: wasquith $
# $Date: 2002/08/07 18:41:28 $
# $Revision: 1.9 $

use strict;
use Tkg2::DataMethods::ClassLoader;

use Exporter;
use SelfLoader;

use vars qw(@ISA $EDITOR);
@ISA = qw(Exporter SelfLoader);

$EDITOR = "";

print $::SPLASH "=";

1;

__DATA__

sub new {
# $DATACLASS = Tkg2::DataMethods->new;
   my $self = [ ];
   return bless $self, shift;
}

sub add {
# $DATACLASS->add($DATASET);
   my $self = shift;
   push(@$self, (@_) );
}

sub dropone {
  # $DATACLASS->dropone(2);
   my ($self, $index) = (shift, shift);
   return undef if($index > $#$self or $index < 0);
   my $arrayref = $self;
   splice(@$arrayref, $index, 1);
   $self = $arrayref;
}

sub changeone {
   my ($self, $index, $set) = (shift, shift, shift);
   return undef if($index > $#$self or $index < 0);
   return undef if(ref($set) ne 'Tkg2::DataMethods::DataSet');
   $self->[$index] = $set;
}

sub raise {
  # $DATACLASS->raise(2);
   my ($self, $index) = (shift, shift);
   my $arrayref = $self;
   return undef if($index > $#$arrayref or $index < 0);
   unshift(@$arrayref, splice(@$arrayref, $index, 1) );
   $self = $arrayref;
}

sub lower {
  # $DATACLASS->lower(2);
   my ($self, $index) = (shift, shift);
   my $arrayref = $self;
   return undef if($index > $#$arrayref or $index < 0);
   push(@$arrayref, splice(@$arrayref, $index, 1) );
   $self = $arrayref;
}


sub getone {
  # $data = $DATACLASS->getone(2);
   my ($self, $index) = (shift, shift);
   my ($arrayref, $hash) = ($self, undef);   
   return undef if($index > $#$arrayref or $index < 0);
   $hash = $arrayref->[$index];
   return $hash;
}

sub getall {
  # $data = $DATASET->getDataSetinClass;
   my $self = shift;
   my ($arrayref, @data) = ( $self, () ); 
   foreach my $data (@$arrayref) {  
     push(@data, $data);  
   }
   return @data;
}

sub dropall {
   my $self = shift;
   @{$self} = ();
}

1;
