require 'spec_helper'
module JSONAPIonify::Structure::Collections
  TopLevel = JSONAPIonify::Structure::Objects::TopLevel
  describe IncludedResources do
    include JSONAPIObjects

    describe 'each resource must be referenced as a relationship' do
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