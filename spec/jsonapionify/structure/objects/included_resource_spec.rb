require 'spec_helper'
module JSONAPIonify::Structure::Objects
  describe IncludedResource do
    include JSONAPIObjects
    # Compound Documents
    # To reduce the number of HTTP requests, servers **MAY** allow responses that
    # include related resources along with the requested primary resources. Such
    # responses are called "compound documents".
    #
    # In a compound document, all included resources **MUST** be represented as an
    # array of resource objects in a top-level `included` member.
    #
    # Compound documents require "full linkage", meaning that every included
    # resource **MUST** be identified by at least one resource identifier object
    # in the same document. These resource identifier objects could either be
    # primary data or represent resource linkage contained within primary or
    # included resources. The only exception to the full linkage requirement is
    # when relationship fields that would otherwise contain linkage data are
    # excluded via sparse fieldsets.
    #
    # > Note: Full linkage ensures that included resources are related to either
    # the primary data (which could be resource object or resource identifier
    # objects) or to each other.
    describe 'full linkage' do
      context 'when properly referenced' do
        context 'in a collection' do
          let(:document) do
            {
              data:     {
                id:            "1",
                type:          "stuff",
                attributes:    {
                  name: "golum"
                },
                relationships: {
                  colors: {
                    data: [{ type: "colors", id: "5" }]
                  }
                },
              },
              included: [
                          {
                            type:       "colors",
                            id:         "5",
                            attributes: {
                              hex: "ff9900"
                            }
                          }
                        ]
            }
          end
          it "should behave like a valid jsonapi object" do
            expect { TopLevel.new(document).compile! }.to_not raise_error
          end
        end

        context 'in an instance' do
          let(:document) do
            {
              data:     {
                id:            "1",
                type:          "stuff",
                attributes:    {
                  name: "golum"
                },
                relationships: {
                  color: {
                    data: { type: "colors", id: "5" }
                  }
                },
              },
              included: [
                          {
                            type:       "colors",
                            id:         "5",
                            attributes: {
                              hex: "ff9900"
                            }
                          }
                        ]
            }
          end
          it "should behave like a valid jsonapi object" do
            expect { TopLevel.new(document).compile! }.to_not raise_error
          end
        end
      end

      context 'when not referenced' do
        context 'in a collection' do
          let(:document) do
            {
              data:     {
                id:            "1",
                type:          "stuff",
                attributes:    {
                  name: "golum"
                },
                relationships: {
                  colors: {
                    data: [{ type: "colors", id: "5" }]
                  }
                },
              },
              included: [
                          {
                            type:       "colors",
                            id:         "4",
                            attributes: {
                              hex: "ff9900"
                            }
                          }
                        ]
            }
          end
          it "should behave like a valid jsonapi object" do
            expect { TopLevel.new(document).compile! }.to raise_error JSONAPIonify::Structure::Helpers::ValidationError
          end
        end

        context 'in an instance' do
          let(:document) do
            {
              data:     {
                id:            "1",
                type:          "stuff",
                attributes:    {
                  name: "golum"
                },
                relationships: {
                  color: {
                    data: { type: "colors", id: "5" }
                  }
                },
              },
              included: [
                          {
                            type:       "colors",
                            id:         "4",
                            attributes: {
                              hex: "ff9900"
                            }
                          }
                        ]
            }
          end
          it "should behave like an invalid jsonapi object" do
            expect { TopLevel.new(document).compile! }.to raise_error JSONAPIonify::Structure::Helpers::ValidationError
          end
        end
      end

      context 'when referenced in included' do
        context 'when the parent is referenced in data' do
          context 'in a collection' do
            let(:document) do
              {
                data:     {
                  id:            "1",
                  type:          "stuff",
                  attributes:    {
                    name: "golum"
                  },
                  relationships: {
                    colors: {
                      data: [{ type: "colors", id: "4" }]
                    }
                  },
                },
                included: [
                            {
                              type:          "colors",
                              id:            "4",
                              attributes:    {
                                hex: "ff9900"
                              },
                              relationships: {
                                similar_colors: {
                                  data: { type: "colors", id: "5" }
                                }
                              }
                            },
                            {
                              type:       "colors",
                              id:         "5",
                              attributes: {
                                hex: "ff9900"
                              }
                            }
                          ]
              }
            end
            it "should behave like a valid jsonapi object" do
              expect { TopLevel.new(document).compile! }.to_not raise_error
            end
          end

          context 'in an instance' do
            let(:document) do
              {
                data:     {
                  id:            "1",
                  type:          "stuff",
                  attributes:    {
                    name: "golum"
                  },
                  relationships: {
                    color: {
                      data: { type: "colors", id: "4" }
                    }
                  },
                },
                included: [
                            {
                              type:          "colors",
                              id:            "4",
                              attributes:    {
                                hex: "ff9900"
                              },
                              relationships: {
                                similar_colors: {
                                  data: { type: "colors", id: "5" }
                                }
                              }
                            },
                            {
                              type:       "colors",
                              id:         "5",
                              attributes: {
                                hex: "ff9900"
                              }
                            }
                          ]
              }
            end
            it "should behave like a valid jsonapi object" do
              expect { TopLevel.new(document).compile! }.to_not raise_error
            end
          end
        end

        context 'when the parent is not referenced in data' do
          context 'when the parent is referenced in data' do
            context 'in a collection' do
              let(:document) do
                {
                  data:     {
                    id:            "1",
                    type:          "stuff",
                    attributes:    {
                      name: "golum"
                    },
                    relationships: {
                      colors: {
                        data: [{ type: "colors", id: "3" }]
                      }
                    },
                  },
                  included: [
                              {
                                type:          "colors",
                                id:            "4",
                                attributes:    {
                                  hex: "ff9900"
                                },
                                relationships: {
                                  similar_colors: {
                                    data: { type: "colors", id: "5" }
                                  }
                                }
                              },
                              {
                                type:       "colors",
                                id:         "5",
                                attributes: {
                                  hex: "ff9900"
                                }
                              }
                            ]
                }
              end
              it "should behave like an invalid jsonapi object" do
                expect { TopLevel.new(document).compile! }.to raise_error JSONAPIonify::Structure::Helpers::ValidationError
              end
            end

            context 'in an instance' do
              let(:document) do
                {
                  data:     {
                    id:            "1",
                    type:          "stuff",
                    attributes:    {
                      name: "golum"
                    },
                    relationships: {
                      color: {
                        data: { type: "colors", id: "3" }
                      }
                    },
                  },
                  included: [
                              {
                                type:          "colors",
                                id:            "4",
                                attributes:    {
                                  hex: "ff9900"
                                },
                                relationships: {
                                  similar_colors: {
                                    data: { type: "colors", id: "5" }
                                  }
                                }
                              },
                              {
                                type:       "colors",
                                id:         "5",
                                attributes: {
                                  hex: "ff9900"
                                }
                              }
                            ]
                }
              end
              it "should behave like an invalid jsonapi object" do
                expect { TopLevel.new(document).compile! }.to raise_error JSONAPIonify::Structure::Helpers::ValidationError
              end
            end
          end
        end
      end
    end
  end
end
