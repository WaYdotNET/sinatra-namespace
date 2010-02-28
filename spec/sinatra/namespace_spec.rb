require File.expand_path("../../spec_helper", __FILE__)

describe Sinatra::Namespace do
  [:get, :head, :post, :put, :delete].each do |verb|
    describe "HTTP #{verb.to_s.upcase}" do
      before :each do
        Object.send :remove_const, :App if Object.const_defined? :App
        class ::App < Sinatra::Base
          register Sinatra::Namespace
        end
        app App
      end

      describe :namespace do
        it "should add routes including prefix to the base app" do
          app.namespace "/foo" do
            send(verb, "/bar") { "baz" }
          end
          browse_route(verb, "/foo/bar").should be_ok
          browse_route(verb, "/foo/bar").body.should == "baz" unless verb == :head
        end

        it "should allowes adding routes with no path" do
          app.namespace "/foo" do
            send(verb) { "bar" }
          end
          browse_route(verb, "/foo").should be_ok
          browse_route(verb, "/foo").body.should == "bar" unless verb == :head
        end
      end

      describe :make_namespace do
        it "extends modules make_namespace is called on" do
          mod = Module.new
          mod.should_not respond_to(verb)
          app.make_namespace(mod, :prefix => "/foo")
          mod.should respond_to(verb)
        end

        it "returns the module" do
          mod = Module.new
          app.make_namespace(mod, :prefix => "/foo").should == mod
        end

        it "sets base" do
          app.make_namespace(Module.new, :prefix => "/foo").base.should == app
        end

        it "sets prefix" do
          app.make_namespace(Module.new, :prefix => "/foo").prefix.should == "/foo"
        end

        it "automatically sets a prefix based on module name if none is given" do
          # FooBar = Module.new  <= does not work in Ruby 1.9
          module ::FooBar; end
          app.make_namespace ::FooBar
          ::FooBar.prefix.should == "/foo_bar"
        end

        it "does not add the application name to auto-generated prefixes" do
          #App::FooBar = Module.new <= does not work in Ruby 1.9
          class ::App < Sinatra::Base; module FooBar; end; end
          app.make_namespace App::FooBar
          App::FooBar.prefix.should == "/foo_bar"
        end
      end

      describe :auto_namespace do
        before do
          class ::App < Sinatra::Base; module Foo; end; end
        end

        it "detects #{verb}" do
          App::Foo.should_not respond_to(verb)
          App::Foo.send(verb, "/bar") { "baz" }
          App::Foo.should respond_to(verb)
          browse_route(verb, "/foo/bar").should be_ok
          browse_route(verb, "/foo/bar").body.should == "baz" unless verb == :head
        end

        it "ignores #{verb} if auto namespaceing is disabled" do
          app.disable :auto_namespace
          App::Foo.should_not respond_to(verb)
          proc { App::Foo.send(verb, "/bar") { "baz" } }.should raise_error(NameError)
          App::Foo.should_not respond_to(verb)
        end

        it "ignores #{verb} if told to via :except" do
          app.set :auto_namespace, :except => verb
          App::Foo.should_not respond_to(verb)
          proc { App::Foo.send(verb, "/bar") { "baz" } }.should raise_error(NameError)
          App::Foo.should_not respond_to(verb)
        end

        it "does not ignore #{verb} if not included in :except" do
          app.set :auto_namespace, :except => ["prefix"]
          App::Foo.should_not respond_to(verb)
          App::Foo.send(verb, "/bar") { "baz" }
          App::Foo.should respond_to(verb)
        end

        it "does ignore #{verb} if not included in :only" do
          app.set :auto_namespace, :only => "prefix"
          App::Foo.should_not respond_to(verb)
          proc { App::Foo.send(verb, "/bar") { "baz" } }.should raise_error(NameError)
          App::Foo.should_not respond_to(verb)
        end

        it "does not ignore #{verb} if included in :only" do
          app.set :auto_namespace, :only => ["prefix", verb]
          App::Foo.should_not respond_to(verb)
          App::Foo.send(verb, "/bar") { "baz" }
          App::Foo.should respond_to(verb)
        end
        
        it "detects prefix" do
          App::Foo.should_not respond_to(:prefix)
          App::Foo.prefix.should == "/foo"
        end
      end

    end
  end
end