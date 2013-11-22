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