module JSONAPIonify
  module EnumerableObserver
    using UnstrictProc
    extend self

    def observe(obj = self, added: proc {}, removed: proc {})
      add_proc    = added
      remove_proc = removed
      (obj.methods - %i{each define_singleton_method}).each do |meth|
        next if meth == :each
        old = obj.method(meth).unbind.bind(obj)
        obj.define_singleton_method(meth) do |*args, &block|
          before  = each.to_a
          val     = old.call(*args, &block)
          after   = each.to_a
          added   = after - before
          removed = before - after
          add_proc.unstrict.call(obj, added) unless added.empty?
          remove_proc.unstrict.call(obj, removed) unless removed.empty?
          val
        end
      end
    end
  end
end
