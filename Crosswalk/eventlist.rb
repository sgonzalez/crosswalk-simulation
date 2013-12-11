#!/usr/bin/env ruby

#######################
## Santiago Gonzalez ##
#######################

EventNode = Struct.new(:when_t, :data)

class Simulation
  
  def init_eventlist
    @eventlist = []
  end
  
  def queue_event when_t, eventdata
    # Update total events
    @totalevents += 1
    # Update events per car (if this is a car event
    if eventdata.include? :car
      if ! @carevents.include? eventdata[:car].uid
        @carevents[eventdata[:car].uid] = 0
      end
      @carevents[eventdata[:car].uid] += 1
    end


    if when_t < 0 or when_t > 10000
      puts "ERROR: Time outside of range! Got #{when_t}. Event: #{eventdata}"
    end
    node = EventNode.new(when_t, eventdata)
    @eventlist << node
    @eventlist.sort_by! &:when_t

  end
  
  def next_event
    if @eventlist.size != 0
      n = @eventlist[0]
      @eventlist.delete n
      @t = n.when_t
      n.data
    else
      nil
    end
  end

  # def show_events( showtime )
  # {
  #   static struct eventnode* hold = NULL;
  #   static size_t h = 0, origcount = 0;;
  # 
  #   if( !hold ) {
  #     assert( count );
  #     // initialize traversal
  #     hold = malloc( sizeof(struct eventnode )*count );
  #     assert( hold );
  #     h = origcount = count;
  #   }
  # 
  #   if( h-- >0 ) {
  #     // traversing 
  #     __next_event( &hold[h], 0 );
  #     *showtime = hold[h].when;
  #     return hold[h].data;
  #   }
  # 
  #   // end of traversal
  #   for( h=origcount; h-- >0; /* empty */ ) {
  #     __queue_event( hold[h].when, hold[h].data );
  #   }
  #   // free holding memory
  #   free( hold );
  #   hold = NULL;
  # 
  #   return NULL;
  # }
  
end
