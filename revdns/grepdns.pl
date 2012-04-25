#!/usr/bin/perl
# This program resolves a list of domains on STDIN, and prints
# something about them on STDOUT.  For testing, I do:
#
# sed 's/$/.com/' /usr/share/dict/words | head -100 | perl resolver.perl
# This program requires features from POE version 0.1702 or higher.
# You can find it at http://poe.perl.org/?Where_to_Get_POE
# This program requires POE::Component::Client::DNS, which can be
# found on the CPAN.
use warnings;
use strict;

# How many resolvers to run at once.  Higher values mean that DNS
# timeouts have less effect on the queue, but it also means your
# nameserver will be hit harder.
sub INITIAL_COUNT () { 7 }

# Include POE and POE::Component::Client::DNS.
use POE;
use POE::Component::Client::DNS;

# Start a DNS resolver agent.  It can resolve several DNS requests in
# parallel.
POE::Component::Client::DNS->spawn(
  Alias       => 'resolver',       # The resolver's symbolic name.
  Timeout     => 5,               # Wait time for resolver answers.
  Nameservers => ['8.8.8.8','8.8.4.4'],    # Resolvers to use.
);

# Get the next domain in the list/file.  This just reads from STDIN,
# returning undef at the end of the file.
sub get_next_domain {
  my $next_domain = <STDIN>;
  return undef unless defined $next_domain;
  chomp $next_domain;
  return $next_domain;
}

# This session will resolve the domains in parallel.  It acts as a
# client for the Client::DNS component.
POE::Session->create(
  inline_states => {
    _start => sub {
      my ($kernel, $heap) = @_[KERNEL, HEAP];

      # Initialize statistical information.
      $heap->{resolver_questions} = 0;
      $heap->{resolver_answers}   = 0;
      $heap->{start_time}         = time();

      # Start the initial set of resolver requests.  New ones will
      # fill their places as old ones complete.
      for (1 .. INITIAL_COUNT) {
        $kernel->yield("start_next_lookup");
      }
    },

    # Display final runtime statistics on STDERR.
    _stop => sub {
      my $heap         = $_[HEAP];
      my $elapsed_time = time() - $heap->{start_time};
      warn(
        "Elapsed time: $elapsed_time second(s).\n",
        "$heap->{resolver_questions} resolver questions.\n",
        "$heap->{resolver_answers} resolver answers.\n",
      );
    },

    # Start a new lookup.  This fetches the next domain and asks the
    # Client::DNS component to resolve it for us.
    start_next_lookup => sub {
      my ($kernel, $heap) = @_[KERNEL, HEAP];

      # Get the next domain.  Don't bother actually starting a
      # lookup if there are no more domains to resolve.
      my $next_domain = get_next_domain();
      return unless defined $next_domain;

      # Ask the resolver (spawned above) to resolve the domain.
      $heap->{resolver_questions}++;
      $kernel->post(
        resolver =>          # Post the message to "resolver".
          resolve =>         # Tell resolver to resolve something.
          got_answer =>      # The event to include an answer with.
          $next_domain =>    # The domain to resolve.
          "A", "IN"          # Net::DNS record type and class to find.
      );
    },

    # As we requested, the resolver sends back answers in "got_answer"
    # messages.  Resolver answers consist two structures in ARG0 and
    # ARG1.  The ARG0 structure contains information about the
    # original request, including the address we asked to look up.
    # The ARG1 structure contains Net::DNS::Resolver information.
    # See Net::DNS for more on that.
    got_answer => sub {
      my ($kernel, $heap) = @_[KERNEL, HEAP];
      my ($request_structure, $response_structure) = @_[ARG0, ARG1];

      # See POE::Component::Client::DNS and Net::DNS.
      my ($net_dns_packet, $net_dns_errorstring) = @$response_structure;

      # Extract the requested address from the original request
      # parameters.
      my $request_address = $request_structure->[0];

      # If there was an error, the Net::DNS packet will be undefined
      # and the error string will say why.  See Net::DNS for more
      # information.
      unless (defined $net_dns_packet) {
        print "$request_address: error ($net_dns_errorstring)\n";

        # Start a new lookup to replace this failed one.
        $kernel->yield("start_next_lookup");
        return;
      }

      # The Net::DNS packet contains an answer() method that returns
      # all the answers for a request.  See Net::DNS for more
      # information.
      my @net_dns_answers = $net_dns_packet->answer();

      # Was the request technically successful, yet it still returned
      # no answers?  Bogus!
      unless (@net_dns_answers) {
        print "$request_address: no answer\n";

        # Start a new lookup to replace this failed one.
        $kernel->yield("start_next_lookup");
        return;
      }

      # Print each answer.
      foreach my $net_dns_answer (@net_dns_answers) {
        $heap->{resolver_answers}++;
        printf(
          "%25s (%-10.10s) %s\n",
          $request_address,            # The requested address.
          $net_dns_answer->type,       # The response type (A, MX, etc.)
          $net_dns_answer->rdatastr    # The response data.
        );
      }

      # Start a new lookup to replace this successful one.
      $kernel->yield("start_next_lookup");
    },
  },
);

# Run the requests, and exit when they are done.
$poe_kernel->run();
exit 0;

